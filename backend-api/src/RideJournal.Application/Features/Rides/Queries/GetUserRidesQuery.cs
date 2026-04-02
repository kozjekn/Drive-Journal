using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Queries;

public record GetUserRidesQuery(string UserId) : IRequest<List<RideDto>>;
