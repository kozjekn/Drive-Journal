using AutoMapper;
using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Auth.Commands;
using DriveJournal.Application.Interfaces;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Handlers;

public class LoginCommandHandler : IRequestHandler<LoginCommand, AuthResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IJwtService _jwtService;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IMapper _mapper;

    public LoginCommandHandler(
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        IJwtService jwtService,
        IPasswordHasher passwordHasher,
        IMapper mapper)
    {
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _jwtService = jwtService;
        _passwordHasher = passwordHasher;
        _mapper = mapper;
    }

    public async Task<AuthResponse> Handle(LoginCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;

        var user = await _userRepository.GetByEmailAsync(request.Email.ToLowerInvariant());
        if (user == null || user.PasswordHash == null)
            throw new UnauthorizedException("Invalid email or password.");

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedException("Invalid email or password.");

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
