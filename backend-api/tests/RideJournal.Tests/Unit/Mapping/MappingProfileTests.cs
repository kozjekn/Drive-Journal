using AutoMapper;
using RideJournal.Application.Mapping;
using FluentAssertions;

namespace RideJournal.Tests.Unit.Mapping;

public class MappingProfileTests
{
    [Fact]
    public void AutoMapper_Configuration_Should_Be_Valid()
    {
        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        config.AssertConfigurationIsValid();
    }
}
