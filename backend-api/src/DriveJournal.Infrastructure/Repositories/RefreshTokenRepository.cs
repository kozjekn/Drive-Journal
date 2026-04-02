using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using DriveJournal.Infrastructure.Persistence;
using MongoDB.Driver;

namespace DriveJournal.Infrastructure.Repositories;

public class RefreshTokenRepository : IRefreshTokenRepository
{
    private readonly MongoDbContext _context;

    public RefreshTokenRepository(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<RefreshToken?> GetByTokenAsync(string token)
    {
        return await _context.RefreshTokens.Find(t => t.Token == token).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(RefreshToken refreshToken)
    {
        await _context.RefreshTokens.InsertOneAsync(refreshToken);
    }

    public async Task RevokeAsync(string token)
    {
        var update = Builders<RefreshToken>.Update.Set(t => t.IsRevoked, true);
        await _context.RefreshTokens.UpdateOneAsync(t => t.Token == token, update);
    }

    public async Task RevokeAllForUserAsync(string userId)
    {
        var update = Builders<RefreshToken>.Update.Set(t => t.IsRevoked, true);
        await _context.RefreshTokens.UpdateManyAsync(t => t.UserId == userId && !t.IsRevoked, update);
    }
}
