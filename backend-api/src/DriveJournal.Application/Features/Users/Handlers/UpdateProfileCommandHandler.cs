using DriveJournal.Application.DTOs.Users;
using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Users.Commands;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Users.Handlers;

public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, UserProfileDto>
{
    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public UpdateProfileCommandHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<UserProfileDto> Handle(UpdateProfileCommand command, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(command.UserId);
        if (user == null)
            throw new NotFoundException("User not found.");

        user.DisplayName = command.Request.DisplayName;
        user.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(user);

        var followerCount = await _followRepository.GetFollowerCountAsync(command.UserId);
        var followingCount = await _followRepository.GetFollowingCountAsync(command.UserId);

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
