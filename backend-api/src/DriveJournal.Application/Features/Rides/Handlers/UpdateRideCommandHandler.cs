using AutoMapper;
using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Rides.Commands;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Handlers;

public class UpdateRideCommandHandler : IRequestHandler<UpdateRideCommand, RideDto>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public UpdateRideCommandHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<RideDto> Handle(UpdateRideCommand command, CancellationToken cancellationToken)
    {
        var ride = await _rideRepository.GetByIdAsync(command.RideId);
        if (ride == null)
            throw new NotFoundException($"Ride with id '{command.RideId}' not found.");

        if (ride.UserId != command.UserId)
            throw new ForbiddenException("You can only edit your own rides.");

        ride.Name = command.Request.Name;
        ride.Visibility = command.Request.Visibility;
        ride.UpdatedAt = DateTime.UtcNow;

        await _rideRepository.UpdateAsync(ride);
        return _mapper.Map<RideDto>(ride);
    }
}
