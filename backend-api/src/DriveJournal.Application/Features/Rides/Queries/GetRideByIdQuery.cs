using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Queries;

public record GetRideByIdQuery(string RideId, string UserId) : IRequest<RideDto>;
