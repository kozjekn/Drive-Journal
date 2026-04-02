using DriveJournal.Domain.Entities;

namespace DriveJournal.Domain.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(string id);
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByGoogleIdAsync(string googleId);
    Task<List<User>> SearchAsync(string query, int skip = 0, int limit = 20);
    Task CreateAsync(User user);
    Task UpdateAsync(User user);
}
