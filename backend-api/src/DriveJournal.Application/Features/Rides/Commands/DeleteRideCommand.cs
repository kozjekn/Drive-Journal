using MediatR;

namespace DriveJournal.Application.Features.Rides.Commands;

public record DeleteRideCommand(string RideId, string UserId) : IRequest<Unit>;
