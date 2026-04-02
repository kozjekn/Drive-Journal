using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Application.Features.Rides.Handlers;
using RideJournal.Application.Mapping;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Enums;
using RideJournal.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace RideJournal.Tests.Unit.Handlers;

public class SyncRidesCommandHandlerTests
{
    private readonly Mock<IRideRepository> _rideRepo = new();
    private readonly IMapper _mapper;
    private readonly SyncRidesCommandHandler _handler;

    public SyncRidesCommandHandlerTests()
    {
        _mapper = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>()).CreateMapper();
        _handler = new SyncRidesCommandHandler(_rideRepo.Object, _mapper);
    }

    [Fact]
    public async Task Handle_Should_Create_New_Rides_From_Client()
    {
        var clientRide = new RideDto
        {
            Id = "ride-1",
            Name = "Morning Ride",
            DistanceMeters = 5000,
            DurationMs = 600000,
            StartTime = DateTime.UtcNow.AddHours(-2),
            UpdatedAt = DateTime.UtcNow,
            Visibility = RideVisibility.Private
        };

        var request = new SyncRidesRequest
        {
            LastSyncAt = null,
            Rides = new List<RideDto> { clientRide }
        };

        _rideRepo.Setup(r => r.GetByIdAsync("ride-1")).ReturnsAsync((Ride?)null);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>()))
            .ReturnsAsync(new List<Ride>());

        var result = await _handler.Handle(new SyncRidesCommand(request, "user-1"), CancellationToken.None);

        result.SyncedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
        result.UpdatedRides.Should().BeEmpty();
        _rideRepo.Verify(r => r.CreateAsync(It.Is<Ride>(ride => ride.Id == "ride-1")), Times.Once);
    }

    [Fact]
    public async Task Handle_Should_Update_When_Client_Is_Newer()
    {
        var serverRide = new Ride
        {
            Id = "ride-1",
            UserId = "user-1",
            Name = "Old Name",
            UpdatedAt = DateTime.UtcNow.AddHours(-1)
        };

        var clientRide = new RideDto
        {
            Id = "ride-1",
            Name = "New Name",
            UpdatedAt = DateTime.UtcNow,
            Visibility = RideVisibility.Private
        };

        var request = new SyncRidesRequest
        {
            LastSyncAt = DateTime.UtcNow.AddHours(-2),
            Rides = new List<RideDto> { clientRide }
        };

        _rideRepo.Setup(r => r.GetByIdAsync("ride-1")).ReturnsAsync(serverRide);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>()))
            .ReturnsAsync(new List<Ride>());

        var result = await _handler.Handle(new SyncRidesCommand(request, "user-1"), CancellationToken.None);

        _rideRepo.Verify(r => r.UpsertAsync(It.Is<Ride>(ride => ride.Name == "New Name")), Times.Once);
    }

    [Fact]
    public async Task Handle_Should_Not_Update_When_Server_Is_Newer()
    {
        var serverRide = new Ride
        {
            Id = "ride-1",
            UserId = "user-1",
            Name = "Server Name",
            UpdatedAt = DateTime.UtcNow
        };

        var clientRide = new RideDto
        {
            Id = "ride-1",
            Name = "Client Name",
            UpdatedAt = DateTime.UtcNow.AddHours(-1),
            Visibility = RideVisibility.Private
        };

        var request = new SyncRidesRequest
        {
            LastSyncAt = DateTime.UtcNow.AddHours(-2),
            Rides = new List<RideDto> { clientRide }
        };

        _rideRepo.Setup(r => r.GetByIdAsync("ride-1")).ReturnsAsync(serverRide);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>()))
            .ReturnsAsync(new List<Ride>());

        var result = await _handler.Handle(new SyncRidesCommand(request, "user-1"), CancellationToken.None);

        _rideRepo.Verify(r => r.UpsertAsync(It.IsAny<Ride>()), Times.Never);
    }

    [Fact]
    public async Task Handle_Should_Return_Server_Rides_Excluding_Client_Ids()
    {
        var serverRide = new Ride
        {
            Id = "ride-2",
            UserId = "user-1",
            Name = "Server Ride",
            UpdatedAt = DateTime.UtcNow,
            StartTime = DateTime.UtcNow.AddHours(-1),
            Visibility = RideVisibility.Private
        };

        var request = new SyncRidesRequest
        {
            LastSyncAt = DateTime.UtcNow.AddHours(-2),
            Rides = new List<RideDto>()
        };

        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>()))
            .ReturnsAsync(new List<Ride> { serverRide });

        var result = await _handler.Handle(new SyncRidesCommand(request, "user-1"), CancellationToken.None);

        result.UpdatedRides.Should().HaveCount(1);
        result.UpdatedRides[0].Id.Should().Be("ride-2");
    }
}
