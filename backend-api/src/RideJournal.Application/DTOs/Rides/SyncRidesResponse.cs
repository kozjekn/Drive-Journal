namespace RideJournal.Application.DTOs.Rides;

public class SyncRidesResponse
{
    /// <summary>
    /// Cursor to send as <c>lastSyncAt</c> on the next call. When the pull was
    /// truncated this is the last returned ride's <c>ServerUpdatedAt</c> rather
    /// than "now", so paging cannot skip a ride written mid-sequence.
    /// </summary>
    public DateTime SyncedAt { get; set; }

    public List<RideDto> UpdatedRides { get; set; } = new();
    public List<string> DeletedRideIds { get; set; } = new();

    /// <summary>True when more rides are waiting past <see cref="SyncedAt"/>.</summary>
    public bool HasMore { get; set; }
}
