using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Commands;

public record CreateRideCommand(CreateRideRequest Request, string UserId) : IRequest<CreateRideResult>;

/// <summary>
/// <paramref name="Created"/> is false when the id already existed, so the
/// controller can answer 200 instead of 201 for an idempotent replay.
/// </summary>
public record CreateRideResult(RideDto Ride, bool Created);
