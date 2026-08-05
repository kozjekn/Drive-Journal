using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class DeleteRideCommandHandler : IRequestHandler<DeleteRideCommand, Unit>
{
    private readonly IRideRepository _rideRepository;

    public DeleteRideCommandHandler(IRideRepository rideRepository)
    {
        _rideRepository = rideRepository;
    }

    /// <remarks>
    /// Soft-deletes, so the deletion can propagate to other devices via
    /// <c>SyncRidesResponse.DeletedRideIds</c>, and is idempotent, so a client
    /// retrying a delete it already completed does not get a 404.
    /// </remarks>
    public async Task<Unit> Handle(DeleteRideCommand command, CancellationToken cancellationToken)
    {
        var ride = await _rideRepository.GetByIdIncludingDeletedAsync(command.RideId);
        if (ride == null)
            throw new NotFoundException($"Ride with id '{command.RideId}' not found.");

        if (ride.UserId != command.UserId)
            throw new ForbiddenException("You can only delete your own rides.");

        if (ride.DeletedAt != null)
            return Unit.Value; // Already gone; the retry got the intended result.

        await _rideRepository.SoftDeleteAsync(command.RideId);
        return Unit.Value;
    }
}
