using AutoMapper;
using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Rides.Commands;
using DriveJournal.Application.Features.Rides.Handlers;
using DriveJournal.Application.Features.Rides.Queries;
using DriveJournal.Application.Mapping;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Enums;
using DriveJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace DriveJournal.Tests.Unit.Handlers;

public class RideCrudHandlerTests
{
    private readonly Mock<IRideRepository> _rideRepo = new();
    private readonly Mock<IFollowRepository> _followRepo = new();
    private readonly IMapper _mapper;

    public RideCrudHandlerTests()
    {
        _mapper = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>()).CreateMapper();
    }

    [Fact]
    public async Task CreateRide_Should_Create_And_Return_Dto()
    {
        var handler = new CreateRideCommandHandler(_rideRepo.Object, _mapper);
        var request = new CreateRideRequest
        {
            Id = "ride-1",
            Name = "Test Ride",
            DistanceMeters = 1000,
            DurationMs = 60000,
            StartTime = DateTime.UtcNow.AddHours(-1),
            Visibility = RideVisibility.Private
        };

        var result = await handler.Handle(new CreateRideCommand(request, "user-1"), CancellationToken.None);

        result.Id.Should().Be("ride-1");
        result.Name.Should().Be("Test Ride");
        result.UserId.Should().Be("user-1");
        _rideRepo.Verify(r => r.CreateAsync(It.IsAny<Ride>()), Times.Once);
    }

    [Fact]
    public async Task UpdateRide_Should_Throw_When_Not_Owner()
    {
        var handler = new UpdateRideCommandHandler(_rideRepo.Object, _mapper);
        _rideRepo.Setup(r => r.GetByIdAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "other-user" });

        var act = () => handler.Handle(
            new UpdateRideCommand("ride-1", new UpdateRideRequest { Name = "New" }, "user-1"),
            CancellationToken.None);

        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task DeleteRide_Should_Throw_When_Not_Owner()
    {
        var handler = new DeleteRideCommandHandler(_rideRepo.Object);
        _rideRepo.Setup(r => r.GetByIdAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "other-user" });

        var act = () => handler.Handle(new DeleteRideCommand("ride-1", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task DeleteRide_Should_Delete_When_Owner()
    {
        var handler = new DeleteRideCommandHandler(_rideRepo.Object);
        _rideRepo.Setup(r => r.GetByIdAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "user-1" });

        await handler.Handle(new DeleteRideCommand("ride-1", "user-1"), CancellationToken.None);
        _rideRepo.Verify(r => r.DeleteAsync("ride-1"), Times.Once);
    }

    [Fact]
    public async Task GetRideById_Should_Throw_When_Private_And_Not_Owner()
    {
        var handler = new GetRideByIdQueryHandler(_rideRepo.Object, _followRepo.Object, _mapper);
        _rideRepo.Setup(r => r.GetByIdAsync("ride-1"))
            .ReturnsAsync(new Ride
            {
                Id = "ride-1",
                UserId = "other-user",
                Visibility = RideVisibility.Private
            });

        var act = () => handler.Handle(new GetRideByIdQuery("ride-1", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task GetPublicRide_Should_Throw_When_Not_Public()
    {
        var handler = new GetPublicRideQueryHandler(_rideRepo.Object, _mapper);
        _rideRepo.Setup(r => r.GetByIdAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", Visibility = RideVisibility.Followers });

        var act = () => handler.Handle(new GetPublicRideQuery("ride-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ForbiddenException>();
    }
}
