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

    public async Task<Ride?> GetByIdAsync(string id)
    {
        return await _context.Rides.Find(r => r.Id == id).FirstOrDefaultAsync();
    }

    public async Task<List<Ride>> GetByUserIdAsync(string userId)
    {
        return await _context.Rides
            .Find(r => r.UserId == userId)
            .SortByDescending(r => r.StartTime)
            .ToListAsync();
    }

    public async Task<List<Ride>> GetFeedRidesAsync(List<string> followeeIds, int skip = 0, int limit = 20)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.In(r => r.UserId, followeeIds),
            Builders<Ride>.Filter.In(r => r.Visibility, new[] { RideVisibility.Followers, RideVisibility.Public })
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
            Builders<Ride>.Filter.Eq(r => r.Visibility, RideVisibility.Public)
        );

        return await _context.Rides
            .Find(filter)
            .SortByDescending(r => r.StartTime)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Ride>> GetUpdatedAfterAsync(string userId, DateTime after, List<string> excludeIds)
    {
        var filter = Builders<Ride>.Filter.And(
            Builders<Ride>.Filter.Eq(r => r.UserId, userId),
            Builders<Ride>.Filter.Gt(r => r.UpdatedAt, after),
            Builders<Ride>.Filter.Nin(r => r.Id, excludeIds)
        );

        return await _context.Rides.Find(filter).ToListAsync();
    }

    public async Task CreateAsync(Ride ride)
    {
        await _context.Rides.InsertOneAsync(ride);
    }

    public async Task UpdateAsync(Ride ride)
    {
        await _context.Rides.ReplaceOneAsync(r => r.Id == ride.Id, ride);
    }

    public async Task UpsertAsync(Ride ride)
    {
        await _context.Rides.ReplaceOneAsync(
            r => r.Id == ride.Id,
            ride,
            new ReplaceOptions { IsUpsert = true });
    }

    public async Task DeleteAsync(string id)
    {
        await _context.Rides.DeleteOneAsync(r => r.Id == id);
    }
}
