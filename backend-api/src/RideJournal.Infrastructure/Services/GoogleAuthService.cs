using System.Net.Http.Json;
using RideJournal.Application.Interfaces;
using RideJournal.Infrastructure.Settings;
using Microsoft.Extensions.Options;

namespace RideJournal.Infrastructure.Services;

public class GoogleAuthService : IGoogleAuthService
{
    private readonly GoogleAuthSettings _settings;
    private readonly HttpClient _httpClient;

    public GoogleAuthService(IOptions<GoogleAuthSettings> settings, HttpClient httpClient)
    {
        _settings = settings.Value;
        _httpClient = httpClient;
    }

    public async Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"https://oauth2.googleapis.com/tokeninfo?id_token={idToken}");

            if (!response.IsSuccessStatusCode)
                return null;

            var tokenInfo = await response.Content.ReadFromJsonAsync<GoogleTokenInfo>();
            if (tokenInfo == null)
                return null;

            if (!string.IsNullOrEmpty(_settings.ClientId) && tokenInfo.Aud != _settings.ClientId)
                return null;

            return new GoogleUserInfo
            {
                GoogleId = tokenInfo.Sub,
                Email = tokenInfo.Email,
                DisplayName = tokenInfo.Name ?? tokenInfo.Email,
                PictureUrl = tokenInfo.Picture
            };
        }
        catch
        {
            return null;
        }
    }

    private class GoogleTokenInfo
    {
        public string Sub { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Name { get; set; }
        public string? Picture { get; set; }
        public string Aud { get; set; } = string.Empty;
    }
}
