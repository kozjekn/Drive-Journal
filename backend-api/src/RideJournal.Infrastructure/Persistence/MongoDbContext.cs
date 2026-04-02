using RideJournal.Domain.Entities;
using RideJournal.Infrastructure.Settings;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace RideJournal.Infrastructure.Persistence;

public class MongoDbContext
{
    private readonly IMongoDatabase _database;

    public MongoDbContext(IOptions<MongoDbSettings> settings)
    {
        var client = new MongoClient(settings.Value.ConnectionString);
        _database = client.GetDatabase(settings.Value.DatabaseName);
    }

    public IMongoCollection<User> Users => _database.GetCollection<User>("users");
    public IMongoCollection<Ride> Rides => _database.GetCollection<Ride>("rides");
    public IMongoCollection<Follow> Follows => _database.GetCollection<Follow>("follows");
    public IMongoCollection<RefreshToken> RefreshTokens => _database.GetCollection<RefreshToken>("refresh_tokens");
}
