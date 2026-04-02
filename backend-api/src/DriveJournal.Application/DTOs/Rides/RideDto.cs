using DriveJournal.Domain.Enums;

namespace DriveJournal.Application.DTOs.Rides;

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
    public DateTime UpdatedAt { get; set; }
}
