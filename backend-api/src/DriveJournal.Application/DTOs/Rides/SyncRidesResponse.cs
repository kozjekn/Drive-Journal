namespace DriveJournal.Application.DTOs.Rides;

public class SyncRidesResponse
{
    public DateTime SyncedAt { get; set; }
    public List<RideDto> UpdatedRides { get; set; } = new();
    public List<string> DeletedRideIds { get; set; } = new();
}
