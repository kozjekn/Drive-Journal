using RideJournal.Domain.Entities;

namespace RideJournal.Domain.Interfaces;

public interface IFollowRepository
{
    Task<Follow?> GetAsync(string followerId, string followeeId);
    Task<List<Follow>> GetFollowersAsync(string userId, int skip = 0, int limit = 50);
    Task<List<Follow>> GetFollowingAsync(string userId, int skip = 0, int limit = 50);
    Task<List<string>> GetFolloweeIdsAsync(string userId);
    Task<bool> IsFollowingAsync(string followerId, string followeeId);
    Task<int> GetFollowerCountAsync(string userId);
    Task<int> GetFollowingCountAsync(string userId);
    Task CreateAsync(Follow follow);
    Task DeleteAsync(string followerId, string followeeId);
}
