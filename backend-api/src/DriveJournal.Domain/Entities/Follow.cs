namespace DriveJournal.Domain.Entities;

public class Follow
{
    public string Id { get; set; } = string.Empty;
    public string FollowerId { get; set; } = string.Empty;
    public string FolloweeId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
