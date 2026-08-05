using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

/// <summary>
/// Backs <c>GET /api/rides/user/{userId}/public</c>. The client already called
/// this path, but the endpoint did not exist and returned 404.
/// </summary>
public class GetPublicRidesByUserQueryHandler
    : IRequestHandler<GetPublicRidesByUserQuery, List<RideDto>>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public GetPublicRidesByUserQueryHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<List<RideDto>> Handle(
        GetPublicRidesByUserQuery query, CancellationToken cancellationToken)
    {
        var rides = await _rideRepository.GetPublicRidesByUserIdAsync(
            query.UserId, query.Skip, query.Limit);
        return _mapper.Map<List<RideDto>>(rides);
    }
}
