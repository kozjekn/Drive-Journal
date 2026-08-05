using RideJournal.Application.Exceptions;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Enums;
using RideJournal.Domain.Interfaces;
using RideJournal.Infrastructure.Persistence;
using MongoDB.Driver;

namespace RideJournal.Infrastructure.Repositories;

public class RideRepository : IRideRepository
{
    private readonly MongoDbContext _context;

    public RideRepository(MongoDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Excludes soft-deleted rides. Every read composes with this so a tombstone
    /// is never visible as a live ride.
    /// </summary>
    private static FilterDefinition<Ride> NotDeleted =>
        Builders<Ride>.Filter.Eq(r => r.DeletedAt, null);

    public async Task<Ride?> GetByIdAsync(string id)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.Id, id),
            NotDeleted
        );
        return await _context.Rides.Find(filter).FirstOrDefaultAsync();
    }

    public async Task<Ride?> GetByIdIncludingDeletedAsync(string id)
    {
        return await _context.Rides.Find(r => r.Id == id).FirstOrDefaultAsync();
    }

    public async Task<List<Ride>> GetByUserIdAsync(string userId)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.UserId, userId),
            NotDeleted
        );
        return await _context.Rides
            .Find(filter)
            .SortByDescending(r => r.StartTime)
            .ToListAsync();
    }

    public async Task<List<Ride>> GetFeedRidesAsync(List<string> followeeIds, int skip = 0, int limit = 20)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.In(r => r.UserId, followeeIds),
            Builders<Ride>.Filter.In(r => r.Visibility, new[] { RideVisibility.Followers, RideVisibility.Public }),
            NotDeleted
        );

        return await _context.Rides
            .Find(filter)
            .SortByDescending(r => r.StartTime)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Ride>> GetPublicRidesByUserIdAsync(string userId, int skip = 0, int limit = 20)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.UserId, userId),
            Builders<Ride>.Filter.Eq(r => r.Visibility, RideVisibility.Public),
            NotDeleted
        );

        return await _context.Rides
            .Find(filter)
            .SortByDescending(r => r.StartTime)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Ride>> GetUpdatedAfterAsync(string userId, DateTime after, List<string> excludeIds, int limit)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.UserId, userId),
            // ServerUpdatedAt, not UpdatedAt: the cursor the client sends back is a
            // server timestamp, so comparing it against a client-supplied value
            // would drop rides whenever the two clocks disagree.
            Builders<Ride>.Filter.Gt(r => r.ServerUpdatedAt, after),
            Builders<Ride>.Filter.Nin(r => r.Id, excludeIds),
            NotDeleted
        );

        return await _context.Rides
            .Find(filter)
            // Ascending so the caller can use the last item's ServerUpdatedAt as
            // an exact next-page cursor.
            .SortBy(r => r.ServerUpdatedAt)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<string>> GetDeletedAfterAsync(string userId, DateTime after)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.UserId, userId),
            Builders<Ride>.Filter.Ne(r => r.DeletedAt, null),
            Builders<Ride>.Filter.Gt(r => r.ServerUpdatedAt, after)
        );

        return await _context.Rides
            .Find(filter)
            .Project(r => r.Id)
            .ToListAsync();
    }

    public async Task CreateAsync(Ride ride)
    {
        ride.ServerUpdatedAt = DateTime.UtcNow;
        try
        {
            await _context.Rides.InsertOneAsync(ride);
        }
        catch (MongoWriteException ex)
            when (ex.WriteError?.Category == ServerErrorCategory.DuplicateKey)
        {
            // Surfaced as 409 by ExceptionHandlingMiddleware rather than a 500.
            // The driver detail stays in Infrastructure.
            throw new ConflictException($"Ride with id '{ride.Id}' already exists.");
        }
    }

    public async Task UpdateAsync(Ride ride)
    {
        ride.ServerUpdatedAt = DateTime.UtcNow;
        await _context.Rides.ReplaceOneAsync(r => r.Id == ride.Id, ride);
    }

    public async Task UpsertAsync(Ride ride)
    {
        ride.ServerUpdatedAt = DateTime.UtcNow;
        await _context.Rides.ReplaceOneAsync(
            r => r.Id == ride.Id,
            ride,
            new ReplaceOptions { IsUpsert = true });
    }

    public async Task SoftDeleteAsync(string id)
    {
        var now = DateTime.UtcNow;
        var update = Builders<Ride>.Update
            .Set(r => r.DeletedAt, now)
            .Set(r => r.ServerUpdatedAt, now);

        await _context.Rides.UpdateOneAsync(r => r.Id == id, update);
    }
}
