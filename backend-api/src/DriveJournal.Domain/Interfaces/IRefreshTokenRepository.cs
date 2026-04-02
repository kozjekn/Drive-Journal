using DriveJournal.Domain.Entities;

namespace DriveJournal.Domain.Interfaces;

public interface IRefreshTokenRepository
{
    Task<RefreshToken?> GetByTokenAsync(string token);
    Task CreateAsync(RefreshToken refreshToken);
    Task RevokeAsync(string token);
    Task RevokeAllForUserAsync(string userId);
}
