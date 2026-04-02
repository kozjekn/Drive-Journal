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
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
