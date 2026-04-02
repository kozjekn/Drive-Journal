using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Queries;

public record GetUserRidesQuery(string UserId) : IRequest<List<RideDto>>;
