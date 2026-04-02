using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Queries;

public record GetFeedRidesQuery(string UserId, int Skip = 0, int Limit = 20) : IRequest<List<RideDto>>;
