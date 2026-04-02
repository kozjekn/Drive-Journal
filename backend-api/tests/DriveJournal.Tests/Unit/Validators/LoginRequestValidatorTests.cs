using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.Validators.Auth;
using FluentAssertions;

namespace DriveJournal.Tests.Unit.Validators;

public class LoginRequestValidatorTests
{
    private readonly LoginRequestValidator _validator = new();

    [Fact]
    public async Task Should_Pass_When_Valid()
    {
        var request = new LoginRequest { Email = "test@example.com", Password = "password" };
        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("", "password")]
    [InlineData("invalid", "password")]
    [InlineData("test@example.com", "")]
    public async Task Should_Fail_When_Invalid(string email, string password)
    {
        var request = new LoginRequest { Email = email, Password = password };
        var result = await _validator.ValidateAsync(request);
        result.IsValid.Should().BeFalse();
    }
}
