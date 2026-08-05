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

        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1")).ReturnsAsync((Ride?)null);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
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

        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1")).ReturnsAsync(serverRide);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
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

        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1")).ReturnsAsync(serverRide);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
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

        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Ride> { serverRide });

        var result = await _handler.Handle(new SyncRidesCommand(request, "user-1"), CancellationToken.None);

        result.UpdatedRides.Should().HaveCount(1);
        result.UpdatedRides[0].Id.Should().Be("ride-2");
        result.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Handle_Should_Default_CreatedAt_When_Client_Omits_It()
    {
        // The client's toJson has no createdAt, which used to persist as
        // DateTime.MinValue (year 0001) on every synced ride.
        var clientRide = new RideDto
        {
            Id = "ride-1",
            Name = "Ride",
            UpdatedAt = DateTime.UtcNow,
            Visibility = RideVisibility.Private
        };

        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1")).ReturnsAsync((Ride?)null);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Ride>());

        await _handler.Handle(
            new SyncRidesCommand(
                new SyncRidesRequest { Rides = new List<RideDto> { clientRide } }, "user-1"),
            CancellationToken.None);

        _rideRepo.Verify(
            r => r.CreateAsync(It.Is<Ride>(ride =>
                ride.CreatedAt > new DateTime(2000, 1, 1))),
            Times.Once);
    }

    [Fact]
    public async Task Handle_Should_Store_Ride_Under_Caller_Even_If_Client_Claims_Another_User()
    {
        var clientRide = new RideDto
        {
            Id = "ride-1",
            UserId = "someone-else",
            Name = "Ride",
            UpdatedAt = DateTime.UtcNow,
            Visibility = RideVisibility.Private
        };

        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1")).ReturnsAsync((Ride?)null);
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Ride>());

        await _handler.Handle(
            new SyncRidesCommand(
                new SyncRidesRequest { Rides = new List<RideDto> { clientRide } }, "user-1"),
            CancellationToken.None);

        _rideRepo.Verify(r => r.CreateAsync(It.Is<Ride>(ride => ride.UserId == "user-1")), Times.Once);
    }

    [Fact]
    public async Task Handle_Should_Not_Resurrect_A_Deleted_Ride()
    {
        var deletedAt = DateTime.UtcNow.AddMinutes(-5);
        _rideRepo.Setup(r => r.GetByIdIncludingDeletedAsync("ride-1"))
            .ReturnsAsync(new Ride
            {
                Id = "ride-1",
                UserId = "user-1",
                UpdatedAt = deletedAt,
                DeletedAt = deletedAt
            });
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Ride>());

        // Stale client push, older than the deletion.
        var clientRide = new RideDto
        {
            Id = "ride-1",
            Name = "Stale",
            UpdatedAt = deletedAt.AddMinutes(-10),
            Visibility = RideVisibility.Private
        };

        await _handler.Handle(
            new SyncRidesCommand(
                new SyncRidesRequest { Rides = new List<RideDto> { clientRide } }, "user-1"),
            CancellationToken.None);

        _rideRepo.Verify(r => r.UpsertAsync(It.IsAny<Ride>()), Times.Never);
        _rideRepo.Verify(r => r.CreateAsync(It.IsAny<Ride>()), Times.Never);
    }

    [Fact]
    public async Task Handle_Should_Page_And_Return_Exact_Cursor_When_Truncated()
    {
        // 51 rides come back for a batch size of 50: the handler must trim to 50,
        // flag HasMore, and set SyncedAt to the last RETURNED ride's server
        // timestamp — using "now" would skip rides 51..n on the next page.
        var baseTime = new DateTime(2026, 8, 1, 12, 0, 0, DateTimeKind.Utc);
        var rides = Enumerable.Range(0, 51).Select(i => new Ride
        {
            Id = $"ride-{i}",
            UserId = "user-1",
            Name = $"Ride {i}",
            UpdatedAt = baseTime.AddMinutes(i),
            ServerUpdatedAt = baseTime.AddMinutes(i),
            StartTime = baseTime.AddMinutes(i),
            Visibility = RideVisibility.Private
        }).ToList();

        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(rides);

        var result = await _handler.Handle(
            new SyncRidesCommand(new SyncRidesRequest { Rides = new List<RideDto>() }, "user-1"),
            CancellationToken.None);

        result.UpdatedRides.Should().HaveCount(50);
        result.HasMore.Should().BeTrue();
        result.SyncedAt.Should().Be(baseTime.AddMinutes(49));
    }

    [Fact]
    public async Task Handle_Should_Report_Deleted_Ride_Ids()
    {
        _rideRepo.Setup(r => r.GetUpdatedAfterAsync("user-1", It.IsAny<DateTime>(), It.IsAny<List<string>>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Ride>());
        _rideRepo.Setup(r => r.GetDeletedAfterAsync("user-1", It.IsAny<DateTime>()))
            .ReturnsAsync(new List<string> { "gone-1", "gone-2" });

        var result = await _handler.Handle(
            new SyncRidesCommand(new SyncRidesRequest { Rides = new List<RideDto>() }, "user-1"),
            CancellationToken.None);

        result.DeletedRideIds.Should().BeEquivalentTo(new[] { "gone-1", "gone-2" });
    }
}
