using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Queries;

public record SearchUsersQuery(string Query, string CurrentUserId, int Skip = 0, int Limit = 20) : IRequest<List<UserSearchResultDto>>;
