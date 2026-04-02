using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Queries;

public record GetRideByIdQuery(string RideId, string UserId) : IRequest<RideDto>;
