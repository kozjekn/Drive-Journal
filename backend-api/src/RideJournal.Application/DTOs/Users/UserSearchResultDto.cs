namespace RideJournal.Application.DTOs.Users;

public class UserSearchResultDto
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? ProfilePictureBase64 { get; set; }
    public bool IsFollowing { get; set; }
}
