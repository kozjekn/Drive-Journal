using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Domain.Enums;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class GetPublicRideQueryHandler : IRequestHandler<GetPublicRideQuery, RideDto>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public GetPublicRideQueryHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<RideDto> Handle(GetPublicRideQuery query, CancellationToken cancellationToken)
    {
        var ride = await _rideRepository.GetByIdAsync(query.RideId);
        if (ride == null)
            throw new NotFoundException($"Ride with id '{query.RideId}' not found.");

        if (ride.Visibility != RideVisibility.Public)
            throw new ForbiddenException("This ride is not public.");

        return _mapper.Map<RideDto>(ride);
    }
}
