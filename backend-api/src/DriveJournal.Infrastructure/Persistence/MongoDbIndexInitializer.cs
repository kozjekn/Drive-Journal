using DriveJournal.Domain.Entities;
using MongoDB.Driver;

namespace DriveJournal.Infrastructure.Persistence;

public static class MongoDbIndexInitializer
{
    public static async Task CreateIndexesAsync(MongoDbContext context)
    {
        // Users indexes
        await context.Users.Indexes.CreateManyAsync(new[]
        {
            new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Ascending(u => u.Email),
                new CreateIndexOptions { Unique = true }),
            new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Ascending(u => u.GoogleId),
                new CreateIndexOptions { Sparse = true }),
            new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Text(u => u.DisplayName))
        });

        // Rides indexes
        await context.Rides.Indexes.CreateManyAsync(new[]
        {
            new CreateIndexModel<Ride>(
                Builders<Ride>.IndexKeys.Ascending(r => r.UserId)),
            new CreateIndexModel<Ride>(
                Builders<Ride>.IndexKeys.Ascending(r => r.UserId).Ascending(r => r.UpdatedAt)),
            new CreateIndexModel<Ride>(
                Builders<Ride>.IndexKeys.Ascending(r => r.Visibility).Descending(r => r.StartTime))
        });

        // Follows indexes
        await context.Follows.Indexes.CreateManyAsync(new[]
        {
            new CreateIndexModel<Follow>(
                Builders<Follow>.IndexKeys
                    .Ascending(f => f.FollowerId)
                    .Ascending(f => f.FolloweeId),
                new CreateIndexOptions { Unique = true }),
            new CreateIndexModel<Follow>(
                Builders<Follow>.IndexKeys.Ascending(f => f.FolloweeId))
        });

        // RefreshTokens indexes
        await context.RefreshTokens.Indexes.CreateManyAsync(new[]
        {
            new CreateIndexModel<RefreshToken>(
                Builders<RefreshToken>.IndexKeys.Ascending(t => t.Token),
                new CreateIndexOptions { Unique = true }),
            new CreateIndexModel<RefreshToken>(
                Builders<RefreshToken>.IndexKeys.Ascending(t => t.UserId))
        });
    }
}
