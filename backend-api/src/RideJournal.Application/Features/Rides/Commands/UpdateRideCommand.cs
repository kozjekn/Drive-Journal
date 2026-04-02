using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Commands;

public record UpdateRideCommand(string RideId, UpdateRideRequest Request, string UserId) : IRequest<RideDto>;
