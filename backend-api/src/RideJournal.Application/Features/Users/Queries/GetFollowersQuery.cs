using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Queries;

public record GetFollowersQuery(string UserId, int Skip = 0, int Limit = 50) : IRequest<List<FollowDto>>;
