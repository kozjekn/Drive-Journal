using AutoMapper;
using RideJournal.Application.DTOs.Auth;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Domain.Entities;

namespace RideJournal.Application.Mapping;

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
