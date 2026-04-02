namespace RideJournal.Application.DTOs.Users;

public class FollowDto
{
    public string UserId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? ProfilePictureBase64 { get; set; }
    public DateTime FollowedAt { get; set; }
}
