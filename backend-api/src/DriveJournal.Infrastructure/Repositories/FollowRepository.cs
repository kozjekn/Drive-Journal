using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using DriveJournal.Infrastructure.Persistence;
using MongoDB.Driver;

namespace DriveJournal.Infrastructure.Repositories;

public class FollowRepository : IFollowRepository
{
    private readonly MongoDbContext _context;

    public FollowRepository(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<Follow?> GetAsync(string followerId, string followeeId)
    {
        return await _context.Follows
            .Find(f => f.FollowerId == followerId && f.FolloweeId == followeeId)
            .FirstOrDefaultAsync();
    }

    public async Task<List<Follow>> GetFollowersAsync(string userId, int skip = 0, int limit = 50)
    {
        return await _context.Follows
            .Find(f => f.FolloweeId == userId)
            .SortByDescending(f => f.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Follow>> GetFollowingAsync(string userId, int skip = 0, int limit = 50)
    {
        return await _context.Follows
            .Find(f => f.FollowerId == userId)
            .SortByDescending(f => f.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<string>> GetFolloweeIdsAsync(string userId)
    {
        var follows = await _context.Follows
            .Find(f => f.FollowerId == userId)
            .ToListAsync();

        return follows.Select(f => f.FolloweeId).ToList();
    }

    public async Task<bool> IsFollowingAsync(string followerId, string followeeId)
    {
        return await _context.Follows
            .Find(f => f.FollowerId == followerId && f.FolloweeId == followeeId)
            .AnyAsync();
    }

    public async Task<int> GetFollowerCountAsync(string userId)
    {
        return (int)await _context.Follows.CountDocumentsAsync(f => f.FolloweeId == userId);
    }

    public async Task<int> GetFollowingCountAsync(string userId)
    {
        return (int)await _context.Follows.CountDocumentsAsync(f => f.FollowerId == userId);
    }

    public async Task CreateAsync(Follow follow)
    {
        await _context.Follows.InsertOneAsync(follow);
    }

    public async Task DeleteAsync(string followerId, string followeeId)
    {
        await _context.Follows.DeleteOneAsync(
            f => f.FollowerId == followerId && f.FolloweeId == followeeId);
    }
}
