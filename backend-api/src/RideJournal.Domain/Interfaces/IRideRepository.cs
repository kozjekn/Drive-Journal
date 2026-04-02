using RideJournal.Domain.Entities;
using RideJournal.Domain.Enums;

namespace RideJournal.Domain.Interfaces;

public interface IRideRepository
{
    Task<Ride?> GetByIdAsync(string id);
    Task<List<Ride>> GetByUserIdAsync(string userId);
    Task<List<Ride>> GetFeedRidesAsync(List<string> followeeIds, int skip = 0, int limit = 20);
    Task<List<Ride>> GetPublicRidesByUserIdAsync(string userId, int skip = 0, int limit = 20);
    Task<List<Ride>> GetUpdatedAfterAsync(string userId, DateTime after, List<string> excludeIds);
    Task CreateAsync(Ride ride);
    Task UpdateAsync(Ride ride);
    Task UpsertAsync(Ride ride);
    Task DeleteAsync(string id);
}
