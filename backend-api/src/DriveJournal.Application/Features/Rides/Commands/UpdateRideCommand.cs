using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Commands;

public record UpdateRideCommand(string RideId, UpdateRideRequest Request, string UserId) : IRequest<RideDto>;
