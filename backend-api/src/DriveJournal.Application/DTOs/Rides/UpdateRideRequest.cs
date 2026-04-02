using DriveJournal.Domain.Enums;

namespace DriveJournal.Application.DTOs.Rides;

public class UpdateRideRequest
{
    public string Name { get; set; } = string.Empty;
    public RideVisibility Visibility { get; set; }
}
