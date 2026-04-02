using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Validators.Auth;
using FluentAssertions;

namespace DriveJournal.Tests.Unit.Validators;

public class RegisterRequestValidatorTests
{
    private readonly RegisterRequestValidator _validator = new();

    [Fact]
    public async Task Should_Pass_When_Valid()
    {
        var request = new RegisterRequest
        {
            Email = "test@example.com",
            Password = "Password1",
            DisplayName = "Test User"
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("", "Password1", "Name", "Email")]
    [InlineData("invalid", "Password1", "Name", "Email")]
    [InlineData("test@example.com", "", "Name", "Password")]
    [InlineData("test@example.com", "short", "Name", "Password")]
    [InlineData("test@example.com", "nouppercase1", "Name", "Password")]
    [InlineData("test@example.com", "NOLOWERCASE1", "Name", "Password")]
    [InlineData("test@example.com", "NoDigitsHere", "Name", "Password")]
    [InlineData("test@example.com", "Password1", "", "DisplayName")]
    public async Task Should_Fail_When_Invalid(string email, string password, string displayName, string expectedProperty)
    {
        var request = new RegisterRequest
        {
            Email = email,
            Password = password,
            DisplayName = displayName
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == expectedProperty);
    }

    [Fact]
    public async Task Should_Fail_When_DisplayName_Too_Long()
    {
        var request = new RegisterRequest
        {
            Email = "test@example.com",
            Password = "Password1",
            DisplayName = new string('A', 51)
        };

        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
    }
}
