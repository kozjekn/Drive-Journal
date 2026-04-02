namespace DriveJournal.Domain.Entities;

public class RoutePoint
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double Altitude { get; set; }
    public double Speed { get; set; }
    public DateTime Timestamp { get; set; }
}
