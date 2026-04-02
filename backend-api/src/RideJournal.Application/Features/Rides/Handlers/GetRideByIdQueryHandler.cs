using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Domain.Enums;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class GetRideByIdQueryHandler : IRequestHandler<GetRideByIdQuery, RideDto>
{
    private readonly IRideRepository _rideRepository;
    private readonly IFollowRepository _followRepository;
    private readonly IMapper _mapper;

    public GetRideByIdQueryHandler(
        IRideRepository rideRepository,
        IFollowRepository followRepository,
        IMapper mapper)
    {
        _rideRepository = rideRepository;
        _followRepository = followRepository;
        _mapper = mapper;
    }

    public async Task<RideDto> Handle(GetRideByIdQuery query, CancellationToken cancellationToken)
    {
        var ride = await _rideRepository.GetByIdAsync(query.RideId);
        if (ride == null)
            throw new NotFoundException($"Ride with id '{query.RideId}' not found.");

        if (ride.UserId != query.UserId)
        {
            if (ride.Visibility == RideVisibility.Private)
                throw new ForbiddenException("This ride is private.");

            if (ride.Visibility == RideVisibility.Followers)
            {
                var isFollowing = await _followRepository.IsFollowingAsync(query.UserId, ride.UserId);
                if (!isFollowing)
                    throw new ForbiddenException("This ride is only visible to followers.");
            }
        }

        return _mapper.Map<RideDto>(ride);
    }
}
