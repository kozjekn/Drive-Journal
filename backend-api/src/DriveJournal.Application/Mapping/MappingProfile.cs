using AutoMapper;
using DriveJournal.Application.DTOs.Auth;
using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Domain.Entities;

namespace DriveJournal.Application.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // User -> UserDto
        CreateMap<User, UserDto>();

        // Ride <-> RideDto
        CreateMap<Ride, RideDto>();
        CreateMap<RideDto, Ride>();

        // RoutePoint <-> RoutePointDto
        CreateMap<RoutePoint, RoutePointDto>();
        CreateMap<RoutePointDto, RoutePoint>();

        // CreateRideRequest -> Ride
        CreateMap<CreateRideRequest, Ride>()
            .ForMember(dest => dest.UserId, opt => opt.Ignore())
            .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
            .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
    }
}
