using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Queries;

public record GetFollowingQuery(string UserId, int Skip = 0, int Limit = 50) : IRequest<List<FollowDto>>;
