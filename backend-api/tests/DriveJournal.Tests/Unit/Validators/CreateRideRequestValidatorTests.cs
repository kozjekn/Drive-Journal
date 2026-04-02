using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Application.Validators.Rides;
using DriveJournal.Domain.Enums;
using FluentAssertions;

namespace DriveJournal.Tests.Unit.Validators;

public class CreateRideRequestValidatorTests
{
    private readonly CreateRideRequestValidator _validator = new();

    [Fact]
    public async Task Should_Pass_When_Valid()
    {
        var request = new CreateRideRequest
        {
            Name = "Morning Ride",
            DistanceMeters = 1000,
            DurationMs = 60000,
            StartTime = DateTime.UtcNow.AddHours(-1),
            Visibility = RideVisibility.Private
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public async Task Should_Fail_When_Name_Empty()
    {
        var request = new CreateRideRequest
        {
            Name = "",
            StartTime = DateTime.UtcNow
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "Name");
    }

    [Fact]
    public async Task Should_Fail_When_Name_Too_Long()
    {
        var request = new CreateRideRequest
        {
            Name = new string('A', 101),
            StartTime = DateTime.UtcNow
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
    }

    [Fact]
    public async Task Should_Fail_When_Distance_Negative()
    {
        var request = new CreateRideRequest
        {
            Name = "Test",
            DistanceMeters = -1,
            StartTime = DateTime.UtcNow
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
    }
}
