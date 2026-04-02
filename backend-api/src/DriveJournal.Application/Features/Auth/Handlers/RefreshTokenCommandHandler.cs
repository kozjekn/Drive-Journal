using AutoMapper;
using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Auth.Commands;
using DriveJournal.Application.Interfaces;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Handlers;

public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, AuthResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IJwtService _jwtService;
    private readonly IMapper _mapper;

    public RefreshTokenCommandHandler(
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        IJwtService jwtService,
        IMapper mapper)
    {
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _jwtService = jwtService;
        _mapper = mapper;
    }

    public async Task<AuthResponse> Handle(RefreshTokenCommand command, CancellationToken cancellationToken)
    {
        var storedToken = await _refreshTokenRepository.GetByTokenAsync(command.RefreshToken);
        if (storedToken == null || storedToken.IsRevoked || storedToken.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedException("Invalid or expired refresh token.");

        var user = await _userRepository.GetByIdAsync(storedToken.UserId);
        if (user == null)
            throw new UnauthorizedException("User not found.");

        await _refreshTokenRepository.RevokeAsync(command.RefreshToken);

        var accessToken = _jwtService.GenerateAccessToken(user);
        var newRefreshToken = new RefreshToken
        {
            Id = Guid.NewGuid().ToString(),
            UserId = user.Id,
            Token = _jwtService.GenerateRefreshToken(),
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        };

        await _refreshTokenRepository.CreateAsync(newRefreshToken);

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = newRefreshToken.Token,
            ExpiresAt = _jwtService.GetAccessTokenExpiration(),
            User = _mapper.Map<UserDto>(user)
        };
    }
}
