using AutoMapper;
using RideJournal.Application.DTOs.Auth;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Auth.Commands;
using RideJournal.Application.Features.Auth.Handlers;
using RideJournal.Application.Interfaces;
using RideJournal.Application.Mapping;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace RideJournal.Tests.Unit.Handlers;

public class RegisterCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepo = new();
    private readonly Mock<IRefreshTokenRepository> _refreshTokenRepo = new();
    private readonly Mock<IJwtService> _jwtService = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly IMapper _mapper;
    private readonly RegisterCommandHandler _handler;

    public RegisterCommandHandlerTests()
    {
        _mapper = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>()).CreateMapper();
        _handler = new RegisterCommandHandler(
            _userRepo.Object, _refreshTokenRepo.Object,
            _jwtService.Object, _passwordHasher.Object, _mapper);
    }

    [Fact]
    public async Task Handle_Should_Create_User_And_Return_Tokens()
    {
        var request = new RegisterRequest
        {
            Email = "test@example.com",
            Password = "Password1",
            DisplayName = "Test"
        };

        _userRepo.Setup(r => r.GetByEmailAsync(It.IsAny<string>())).ReturnsAsync((User?)null);
        _passwordHasher.Setup(h => h.Hash(It.IsAny<string>())).Returns("hashed");
        _jwtService.Setup(j => j.GenerateAccessToken(It.IsAny<User>())).Returns("access-token");
        _jwtService.Setup(j => j.GenerateRefreshToken()).Returns("refresh-token");
        _jwtService.Setup(j => j.GetAccessTokenExpiration()).Returns(DateTime.UtcNow.AddHours(1));

        var result = await _handler.Handle(new RegisterCommand(request), CancellationToken.None);

        result.AccessToken.Should().Be("access-token");
        result.RefreshToken.Should().Be("refresh-token");
        result.User.Email.Should().Be("test@example.com");
        _userRepo.Verify(r => r.CreateAsync(It.IsAny<User>()), Times.Once);
    }

    [Fact]
    public async Task Handle_Should_Throw_When_Email_Exists()
    {
        var request = new RegisterRequest
        {
            Email = "test@example.com",
            Password = "Password1",
            DisplayName = "Test"
        };

        _userRepo.Setup(r => r.GetByEmailAsync("test@example.com"))
            .ReturnsAsync(new User { Id = "1", Email = "test@example.com" });

        var act = () => _handler.Handle(new RegisterCommand(request), CancellationToken.None);
        await act.Should().ThrowAsync<ConflictException>();
    }
}
