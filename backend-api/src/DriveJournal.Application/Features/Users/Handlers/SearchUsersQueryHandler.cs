using DriveJournal.Application.DTOs.Users;
using DriveJournal.Application.Features.Users.Queries;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Users.Handlers;

public class SearchUsersQueryHandler : IRequestHandler<SearchUsersQuery, List<UserSearchResultDto>>
{
    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public SearchUsersQueryHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<List<UserSearchResultDto>> Handle(SearchUsersQuery query, CancellationToken cancellationToken)
    {
        var users = await _userRepository.SearchAsync(query.Query, query.Skip, query.Limit);
        var results = new List<UserSearchResultDto>();

        foreach (var user in users)
        {
            var isFollowing = await _followRepository.IsFollowingAsync(query.CurrentUserId, user.Id);
            results.Add(new UserSearchResultDto
            {
                Id = user.Id,
                DisplayName = user.DisplayName,
                ProfilePictureBase64 = user.ProfilePictureBase64,
                IsFollowing = isFollowing
            });
        }

        return results;
    }
}
