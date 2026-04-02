using AutoMapper;
using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Auth.Commands;
using DriveJournal.Application.Features.Auth.Handlers;
using DriveJournal.Application.Interfaces;
using DriveJournal.Application.Mapping;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace DriveJournal.Tests.Unit.Handlers;

public class LoginCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepo = new();
    private readonly Mock<IRefreshTokenRepository> _refreshTokenRepo = new();
    private readonly Mock<IJwtService> _jwtService = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly IMapper _mapper;
    private readonly LoginCommandHandler _handler;

    public LoginCommandHandlerTests()
    {
        _mapper = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>()).CreateMapper();
        _handler = new LoginCommandHandler(
            _userRepo.Object, _refreshTokenRepo.Object,
            _jwtService.Object, _passwordHasher.Object, _mapper);
    }

    [Fact]
    public async Task Handle_Should_Return_Tokens_When_Valid()
    {
        var user = new User
        {
            Id = "1",
            Email = "test@example.com",
            DisplayName = "Test",
            PasswordHash = "hashed"
        };

        _userRepo.Setup(r => r.GetByEmailAsync("test@example.com")).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify("Password1", "hashed")).Returns(true);
        _jwtService.Setup(j => j.GenerateAccessToken(user)).Returns("token");
        _jwtService.Setup(j => j.GenerateRefreshToken()).Returns("refresh");
        _jwtService.Setup(j => j.GetAccessTokenExpiration()).Returns(DateTime.UtcNow.AddHours(1));

        var result = await _handler.Handle(
            new LoginCommand(new LoginRequest { Email = "test@example.com", Password = "Password1" }),
            CancellationToken.None);

        result.AccessToken.Should().Be("token");
    }

    [Fact]
    public async Task Handle_Should_Throw_When_User_Not_Found()
    {
        _userRepo.Setup(r => r.GetByEmailAsync(It.IsAny<string>())).ReturnsAsync((User?)null);

        var act = () => _handler.Handle(
            new LoginCommand(new LoginRequest { Email = "x@x.com", Password = "p" }),
            CancellationToken.None);

        await act.Should().ThrowAsync<UnauthorizedException>();
    }

    [Fact]
    public async Task Handle_Should_Throw_When_Wrong_Password()
    {
        var user = new User { Id = "1", Email = "test@example.com", PasswordHash = "hashed" };
        _userRepo.Setup(r => r.GetByEmailAsync("test@example.com")).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify(It.IsAny<string>(), It.IsAny<string>())).Returns(false);

        var act = () => _handler.Handle(
            new LoginCommand(new LoginRequest { Email = "test@example.com", Password = "wrong" }),
            CancellationToken.None);

        await act.Should().ThrowAsync<UnauthorizedException>();
    }
}
