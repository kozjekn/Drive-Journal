using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Commands;

public record CreateRideCommand(CreateRideRequest Request, string UserId) : IRequest<RideDto>;
