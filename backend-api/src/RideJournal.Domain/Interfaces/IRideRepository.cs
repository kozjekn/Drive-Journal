using RideJournal.Domain.Entities;

namespace RideJournal.Domain.Interfaces;

public interface IRideRepository
{
    Task<Ride?> GetByIdAsync(string id);

    /// <summary>
    /// Includes soft-deleted rides. Sync needs this: a lookup that hid tombstones
    /// would report "no such ride" and let a stale client re-create one it had
    /// already deleted.
    /// </summary>
    Task<Ride?> GetByIdIncludingDeletedAsync(string id);

    Task<List<Ride>> GetByUserIdAsync(string userId);
    Task<List<Ride>> GetFeedRidesAsync(List<string> followeeIds, int skip = 0, int limit = 20);
    Task<List<Ride>> GetPublicRidesByUserIdAsync(string userId, int skip = 0, int limit = 20);

    /// <summary>
    /// Rides written after <paramref name="after"/> on the *server* clock,
    /// oldest first, so the caller can page with an exact cursor.
    /// </summary>
    Task<List<Ride>> GetUpdatedAfterAsync(string userId, DateTime after, List<string> excludeIds, int limit);

    /// <summary>Ids soft-deleted after <paramref name="after"/>.</summary>
    Task<List<string>> GetDeletedAfterAsync(string userId, DateTime after);

    Task CreateAsync(Ride ride);
    Task UpdateAsync(Ride ride);
    Task UpsertAsync(Ride ride);
    Task SoftDeleteAsync(string id);
}
