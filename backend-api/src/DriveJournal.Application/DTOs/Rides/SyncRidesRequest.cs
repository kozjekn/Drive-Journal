namespace DriveJournal.Application.DTOs.Rides;

public class SyncRidesRequest
{
    public DateTime? LastSyncAt { get; set; }
    public List<RideDto> Rides { get; set; } = new();
}
