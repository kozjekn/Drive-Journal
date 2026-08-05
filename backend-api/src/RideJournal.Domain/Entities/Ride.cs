using RideJournal.Domain.Enums;

namespace RideJournal.Domain.Entities;

public class Ride
{
    public string Id { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public double DistanceMeters { get; set; }
    public long DurationMs { get; set; }
    public double AvgSpeedKmh { get; set; }
    public double MaxSpeedKmh { get; set; }
    public double ElevationGainMeters { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public List<RoutePoint> RoutePoints { get; set; } = new();
    public RideVisibility Visibility { get; set; } = RideVisibility.Private;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// The client's logical version of this ride, used only for conflict
    /// resolution (last writer by client clock wins).
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Server-clock write timestamp, stamped by the repository on every write.
    /// This is the sync high-water mark: <see cref="UpdatedAt"/> comes from the
    /// pushing device, so a device whose clock runs behind the server would
    /// silently never propagate to other devices if the cursor used it.
    /// </summary>
    public DateTime ServerUpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Soft-delete tombstone. Deletes must survive long enough to propagate to
    /// other devices, so rows are never removed outright.
    /// </summary>
    public DateTime? DeletedAt { get; set; }
}
