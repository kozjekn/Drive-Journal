using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class GetFeedRidesQueryHandler : IRequestHandler<GetFeedRidesQuery, List<RideDto>>
{
    private readonly IRideRepository _rideRepository;
    private readonly IFollowRepository _followRepository;
    private readonly IMapper _mapper;

    public GetFeedRidesQueryHandler(
        IRideRepository rideRepository,
        IFollowRepository followRepository,
        IMapper mapper)
    {
        _rideRepository = rideRepository;
        _followRepository = followRepository;
        _mapper = mapper;
    }

    public async Task<List<RideDto>> Handle(GetFeedRidesQuery query, CancellationToken cancellationToken)
    {
        var followeeIds = await _followRepository.GetFolloweeIdsAsync(query.UserId);
        if (!followeeIds.Any())
            return new List<RideDto>();

        var rides = await _rideRepository.GetFeedRidesAsync(followeeIds, query.Skip, query.Limit);
        return _mapper.Map<List<RideDto>>(rides);
    }
}
