using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Application.Features.Rides.Handlers;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Application.Mapping;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Enums;
using RideJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace RideJournal.Tests.Unit.Handlers;

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

        result.Created.Should().BeTrue();
        result.Ride.Id.Should().Be("ride-1");
        result.Ride.Name.Should().Be("Test Ride");
        result.Ride.UserId.Should().Be("user-1");
        _rideRepo.Verify(r => r.CreateAsync(It.IsAny<Ride>()), Times.Once);
    }

    [Fact]
    public async Task CreateRide_Should_Be_Idempotent_For_Same_Owner()
    {
        // Retrying an upload after an ambiguous timeout must not fail: the id is
        // client-generated, and this used to surface as a duplicate-key 500.
        var handler = new CreateRideCommandHandler(_rideRepo.Object, _mapper);
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "user-1", Name = "Stored Ride" });

        var request = new CreateRideRequest { Id = "ride-1", Name = "Retry Ride" };
        var result = await handler.Handle(new CreateRideCommand(request, "user-1"), CancellationToken.None);

        result.Created.Should().BeFalse();
        result.Ride.Name.Should().Be("Stored Ride");
        _rideRepo.Verify(r => r.CreateAsync(It.IsAny<Ride>()), Times.Never);
    }

    [Fact]
    public async Task CreateRide_Should_Conflict_When_Id_Belongs_To_Another_User()
    {
        var handler = new CreateRideCommandHandler(_rideRepo.Object, _mapper);
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "other-user" });

        var act = () => handler.Handle(
            new CreateRideCommand(new CreateRideRequest { Id = "ride-1", Name = "Mine" }, "user-1"),
            CancellationToken.None);

        await act.Should().ThrowAsync<ConflictException>();
        _rideRepo.Verify(r => r.CreateAsync(It.IsAny<Ride>()), Times.Never);
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
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "other-user" });

        var act = () => handler.Handle(new DeleteRideCommand("ride-1", "user-1"), CancellationToken.None);
        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task DeleteRide_Should_SoftDelete_When_Owner()
    {
        var handler = new DeleteRideCommandHandler(_rideRepo.Object);
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride { Id = "ride-1", UserId = "user-1" });

        await handler.Handle(new DeleteRideCommand("ride-1", "user-1"), CancellationToken.None);
        _rideRepo.Verify(r => r.SoftDeleteAsync("ride-1"), Times.Once);
    }

    [Fact]
    public async Task DeleteRide_Should_Be_Idempotent_When_Already_Deleted()
    {
        // A client retrying a delete it already completed must not get a 404.
        var handler = new DeleteRideCommandHandler(_rideRepo.Object);
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride
            {
                Id = "ride-1",
                UserId = "user-1",
                DeletedAt = DateTime.UtcNow.AddMinutes(-5)
            });

        await handler.Handle(new DeleteRideCommand("ride-1", "user-1"), CancellationToken.None);
        _rideRepo.Verify(r => r.SoftDeleteAsync(It.IsAny<string>()), Times.Never);
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
