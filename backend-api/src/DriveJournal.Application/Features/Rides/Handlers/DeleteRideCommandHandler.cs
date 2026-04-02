using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Rides.Commands;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Handlers;

public class DeleteRideCommandHandler : IRequestHandler<DeleteRideCommand, Unit>
{
    private readonly IRideRepository _rideRepository;

    public DeleteRideCommandHandler(IRideRepository rideRepository)
    {
        _rideRepository = rideRepository;
    }

    public async Task<Unit> Handle(DeleteRideCommand command, CancellationToken cancellationToken)
    {
        var ride = await _rideRepository.GetByIdAsync(command.RideId);
        if (ride == null)
            throw new NotFoundException($"Ride with id '{command.RideId}' not found.");

        if (ride.UserId != command.UserId)
            throw new ForbiddenException("You can only delete your own rides.");

        await _rideRepository.DeleteAsync(command.RideId);
        return Unit.Value;
    }
}
