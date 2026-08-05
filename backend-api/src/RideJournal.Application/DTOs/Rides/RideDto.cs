using RideJournal.Domain.Enums;

namespace RideJournal.Application.DTOs.Rides;

public class RideDto
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
    public List<RoutePointDto> RoutePoints { get; set; } = new();
    public RideVisibility Visibility { get; set; }
    public DateTime CreatedAt { get; set; }

    /// <summary>Client's logical version; used for conflict resolution.</summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// Server-clock write time. Read-only for clients — informational only, since
    /// the pull cursor comes from <see cref="SyncRidesResponse.SyncedAt"/>.
    /// </summary>
    public DateTime ServerUpdatedAt { get; set; }
}
