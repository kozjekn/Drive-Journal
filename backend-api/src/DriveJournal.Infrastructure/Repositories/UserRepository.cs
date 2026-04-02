using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using DriveJournal.Infrastructure.Persistence;
using MongoDB.Driver;

namespace DriveJournal.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly MongoDbContext _context;

    public UserRepository(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(string id)
    {
        return await _context.Users.Find(u => u.Id == id).FirstOrDefaultAsync();
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _context.Users.Find(u => u.Email == email).FirstOrDefaultAsync();
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        return await _context.Users.Find(u => u.GoogleId == googleId).FirstOrDefaultAsync();
    }

    public async Task<List<User>> SearchAsync(string query, int skip = 0, int limit = 20)
    {
        var filter = Builders<User>.Filter.Or(
            Builders<User>.Filter.Regex(u => u.DisplayName, new MongoDB.Bson.BsonRegularExpression(query, "i")),
            Builders<User>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(query, "i"))
        );

        return await _context.Users
            .Find(filter)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task CreateAsync(User user)
    {
        await _context.Users.InsertOneAsync(user);
    }

    public async Task UpdateAsync(User user)
    {
        await _context.Users.ReplaceOneAsync(u => u.Id == user.Id, user);
    }
}
