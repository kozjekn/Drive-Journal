using AutoMapper;
using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Application.Features.Rides.Commands;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Handlers;

public class CreateRideCommandHandler : IRequestHandler<CreateRideCommand, RideDto>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public CreateRideCommandHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<RideDto> Handle(CreateRideCommand command, CancellationToken cancellationToken)
    {
        var ride = _mapper.Map<Ride>(command.Request);
        ride.UserId = command.UserId;
        ride.CreatedAt = DateTime.UtcNow;
        ride.UpdatedAt = DateTime.UtcNow;

        if (string.IsNullOrEmpty(ride.Id))
            ride.Id = Guid.NewGuid().ToString();

        await _rideRepository.CreateAsync(ride);
        return _mapper.Map<RideDto>(ride);
    }
}
