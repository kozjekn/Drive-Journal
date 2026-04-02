using AutoMapper;
using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Auth.Commands;
using DriveJournal.Application.Interfaces;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Handlers;

public class GoogleAuthCommandHandler : IRequestHandler<GoogleAuthCommand, AuthResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IJwtService _jwtService;
    private readonly IGoogleAuthService _googleAuthService;
    private readonly IMapper _mapper;

    public GoogleAuthCommandHandler(
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        IJwtService jwtService,
        IGoogleAuthService googleAuthService,
        IMapper mapper)
    {
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _jwtService = jwtService;
        _googleAuthService = googleAuthService;
        _mapper = mapper;
    }

    public async Task<AuthResponse> Handle(GoogleAuthCommand command, CancellationToken cancellationToken)
    {
        var googleUser = await _googleAuthService.ValidateIdTokenAsync(command.IdToken);
        if (googleUser == null)
            throw new UnauthorizedException("Invalid Google ID token.");

        var user = await _userRepository.GetByGoogleIdAsync(googleUser.GoogleId);

        if (user == null)
        {
            user = await _userRepository.GetByEmailAsync(googleUser.Email.ToLowerInvariant());

            if (user != null)
            {
                user.GoogleId = googleUser.GoogleId;
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepository.UpdateAsync(user);
            }
            else
            {
                user = new User
                {
                    Id = Guid.NewGuid().ToString(),
                    Email = googleUser.Email.ToLowerInvariant(),
                    DisplayName = googleUser.DisplayName,
                    GoogleId = googleUser.GoogleId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _userRepository.CreateAsync(user);
            }
        }

        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = new RefreshToken
        {
            Id = Guid.NewGuid().ToString(),
            UserId = user.Id,
            Token = _jwtService.GenerateRefreshToken(),
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        };

        await _refreshTokenRepository.CreateAsync(refreshToken);

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken.Token,
            ExpiresAt = _jwtService.GetAccessTokenExpiration(),
            User = _mapper.Map<UserDto>(user)
        };
    }
}
