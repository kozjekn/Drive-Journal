using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Commands;

public record CreateRideCommand(CreateRideRequest Request, string UserId) : IRequest<RideDto>;
