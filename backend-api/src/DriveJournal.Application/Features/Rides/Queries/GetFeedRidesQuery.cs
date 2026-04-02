using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Queries;

public record GetFeedRidesQuery(string UserId, int Skip = 0, int Limit = 20) : IRequest<List<RideDto>>;
