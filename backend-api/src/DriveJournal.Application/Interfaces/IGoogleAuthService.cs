namespace DriveJournal.Application.Interfaces;

public class GoogleUserInfo
{
    public string GoogleId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? PictureUrl { get; set; }
}

public interface IGoogleAuthService
{
    Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken);
}
