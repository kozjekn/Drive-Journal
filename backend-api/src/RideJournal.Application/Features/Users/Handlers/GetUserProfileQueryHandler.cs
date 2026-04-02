using RideJournal.Application.DTOs.Users;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Users.Queries;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Users.Handlers;

public class GetUserProfileQueryHandler : IRequestHandler<GetUserProfileQuery, UserProfileDto>
{
    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public GetUserProfileQueryHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<UserProfileDto> Handle(GetUserProfileQuery query, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(query.TargetUserId);
        if (user == null)
            throw new NotFoundException("User not found.");

        var followerCount = await _followRepository.GetFollowerCountAsync(query.TargetUserId);
        var followingCount = await _followRepository.GetFollowingCountAsync(query.TargetUserId);
        var isFollowing = await _followRepository.IsFollowingAsync(query.CurrentUserId, query.TargetUserId);

        return new UserProfileDto
        {
            Id = user.Id,
            Email = user.Email,
            DisplayName = user.DisplayName,
            ProfilePictureBase64 = user.ProfilePictureBase64,
            FollowerCount = followerCount,
            FollowingCount = followingCount,
            IsFollowing = isFollowing,
            CreatedAt = user.CreatedAt
        };
    }
}
