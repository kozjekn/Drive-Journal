using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Users.Commands;
using DriveJournal.Application.Features.Users.Handlers;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace DriveJournal.Tests.Unit.Handlers;

public class FollowHandlerTests
{
    private readonly Mock<IUserRepository> _userRepo = new();
    private readonly Mock<IFollowRepository> _followRepo = new();

    [Fact]
    public async Task Follow_Should_Throw_When_Following_Self()
    {
        var handler = new FollowUserCommandHandler(_userRepo.Object, _followRepo.Object);
        var act = () => handler.Handle(new FollowUserCommand("user-1", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task Follow_Should_Throw_When_Target_Not_Found()
    {
        _userRepo.Setup(r => r.GetByIdAsync("user-2")).ReturnsAsync((User?)null);
        var handler = new FollowUserCommandHandler(_userRepo.Object, _followRepo.Object);
        var act = () => handler.Handle(new FollowUserCommand("user-2", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task Follow_Should_Throw_When_Already_Following()
    {
        _userRepo.Setup(r => r.GetByIdAsync("user-2")).ReturnsAsync(new User { Id = "user-2" });
        _followRepo.Setup(r => r.GetAsync("user-1", "user-2"))
            .ReturnsAsync(new Follow { FollowerId = "user-1", FolloweeId = "user-2" });

        var handler = new FollowUserCommandHandler(_userRepo.Object, _followRepo.Object);
        var act = () => handler.Handle(new FollowUserCommand("user-2", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task Follow_Should_Create_Follow()
    {
        _userRepo.Setup(r => r.GetByIdAsync("user-2")).ReturnsAsync(new User { Id = "user-2" });
        _followRepo.Setup(r => r.GetAsync("user-1", "user-2")).ReturnsAsync((Follow?)null);

        var handler = new FollowUserCommandHandler(_userRepo.Object, _followRepo.Object);
        await handler.Handle(new FollowUserCommand("user-2", "user-1"), CancellationToken.None);

        _followRepo.Verify(r => r.CreateAsync(It.Is<Follow>(f =>
            f.FollowerId == "user-1" && f.FolloweeId == "user-2")), Times.Once);
    }

    [Fact]
    public async Task Unfollow_Should_Throw_When_Not_Following()
    {
        _followRepo.Setup(r => r.GetAsync("user-1", "user-2")).ReturnsAsync((Follow?)null);
        var handler = new UnfollowUserCommandHandler(_followRepo.Object);
        var act = () => handler.Handle(new UnfollowUserCommand("user-2", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task Unfollow_Should_Delete_Follow()
    {
        _followRepo.Setup(r => r.GetAsync("user-1", "user-2"))
            .ReturnsAsync(new Follow { FollowerId = "user-1", FolloweeId = "user-2" });

        var handler = new UnfollowUserCommandHandler(_followRepo.Object);
        await handler.Handle(new UnfollowUserCommand("user-2", "user-1"), CancellationToken.None);

        _followRepo.Verify(r => r.DeleteAsync("user-1", "user-2"), Times.Once);
    }
}
