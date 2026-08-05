using FluentValidation;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Application.Validators;
using FluentAssertions;

namespace RideJournal.Tests.Unit.Validators;

/// <summary>
/// Regression tests for the wiring itself. ValidationBehavior resolves
/// IValidator&lt;TCommand&gt;, but every validator targeted the inner request DTO,
/// so nothing validated at runtime — an empty ride name got a 201. These assert
/// the command-level validators exist and delegate.
/// </summary>
public class CommandValidatorTests
{
    [Fact]
    public void CreateRideCommandValidator_Should_Reject_Empty_Name()
    {
        var validator = new CreateRideCommandValidator();
        var command = new CreateRideCommand(
            new CreateRideRequest { Name = "", StartTime = DateTime.UtcNow },
            "user-1");

        var result = validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage.Contains("name is required"));
    }

    [Fact]
    public void CreateRideCommandValidator_Should_Reject_Negative_Distance()
    {
        var validator = new CreateRideCommandValidator();
        var command = new CreateRideCommand(
            new CreateRideRequest
            {
                Name = "Ride",
                DistanceMeters = -5,
                StartTime = DateTime.UtcNow
            },
            "user-1");

        validator.Validate(command).IsValid.Should().BeFalse();
    }

    [Fact]
    public void CreateRideCommandValidator_Should_Accept_A_Valid_Ride()
    {
        var validator = new CreateRideCommandValidator();
        var command = new CreateRideCommand(
            new CreateRideRequest
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Morning Ride",
                DistanceMeters = 12_400,
                DurationMs = 2_520_000,
                StartTime = DateTime.UtcNow.AddHours(-1)
            },
            "user-1");

        validator.Validate(command).IsValid.Should().BeTrue();
    }

    [Fact]
    public void SyncRidesCommandValidator_Should_Reject_Oversized_Batch()
    {
        var validator = new SyncRidesCommandValidator();
        var rides = Enumerable.Range(0, SyncRidesCommandValidator.MaxRidesPerSync + 1)
            .Select(i => new RideDto { Id = $"ride-{i}", Name = $"Ride {i}" })
            .ToList();

        var result = validator.Validate(
            new SyncRidesCommand(new SyncRidesRequest { Rides = rides }, "user-1"));

        result.IsValid.Should().BeFalse();
    }

    [Fact]
    public void SyncRidesCommandValidator_Should_Accept_A_Normal_Batch()
    {
        var validator = new SyncRidesCommandValidator();
        var rides = Enumerable.Range(0, 5)
            .Select(i => new RideDto { Id = $"ride-{i}", Name = $"Ride {i}" })
            .ToList();

        validator.Validate(
                new SyncRidesCommand(new SyncRidesRequest { Rides = rides }, "user-1"))
            .IsValid.Should().BeTrue();
    }
}
