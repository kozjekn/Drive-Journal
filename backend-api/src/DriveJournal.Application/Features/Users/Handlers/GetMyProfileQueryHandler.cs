using DriveJournal.Application.DTOs.Users;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Users.Queries;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Users.Handlers;

public class GetMyProfileQueryHandler : IRequestHandler<GetMyProfileQuery, UserProfileDto>
{
    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public GetMyProfileQueryHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<UserProfileDto> Handle(GetMyProfileQuery query, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(query.UserId);
        if (user == null)
            throw new NotFoundException("User not found.");

        var followerCount = await _followRepository.GetFollowerCountAsync(query.UserId);
        var followingCount = await _followRepository.GetFollowingCountAsync(query.UserId);

        return new UserProfileDto
        {
            Id = user.Id,
            Email = user.Email,
            DisplayName = user.DisplayName,
            ProfilePictureBase64 = user.ProfilePictureBase64,
            FollowerCount = followerCount,
            FollowingCount = followingCount,
            IsFollowing = false,
            CreatedAt = user.CreatedAt
        };
    }
}
