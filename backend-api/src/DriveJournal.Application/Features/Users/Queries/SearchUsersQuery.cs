using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Queries;

public record SearchUsersQuery(string Query, string CurrentUserId, int Skip = 0, int Limit = 20) : IRequest<List<UserSearchResultDto>>;
