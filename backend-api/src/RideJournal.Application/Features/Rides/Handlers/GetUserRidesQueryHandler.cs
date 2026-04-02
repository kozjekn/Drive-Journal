using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Queries;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class GetUserRidesQueryHandler : IRequestHandler<GetUserRidesQuery, List<RideDto>>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public GetUserRidesQueryHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<List<RideDto>> Handle(GetUserRidesQuery query, CancellationToken cancellationToken)
    {
        var rides = await _rideRepository.GetByUserIdAsync(query.UserId);
        return _mapper.Map<List<RideDto>>(rides);
    }
}
