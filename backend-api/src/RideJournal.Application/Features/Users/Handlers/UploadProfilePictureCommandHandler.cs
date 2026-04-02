using RideJournal.Application.DTOs.Users;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Users.Commands;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Users.Handlers;

public class UploadProfilePictureCommandHandler : IRequestHandler<UploadProfilePictureCommand, UserProfileDto>
{
    private const int MaxBase64SizeBytes = 512 * 1024; // ~500KB compressed

    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public UploadProfilePictureCommandHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<UserProfileDto> Handle(UploadProfilePictureCommand command, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(command.UserId);
        if (user == null)
            throw new NotFoundException("User not found.");

        var imageBytes = Convert.FromBase64String(command.Base64Image);
        if (imageBytes.Length > MaxBase64SizeBytes)
            throw new Application.Exceptions.ValidationException(
                new Dictionary<string, string[]>
                {
                    { "Base64Image", new[] { $"Image must be smaller than {MaxBase64SizeBytes / 1024}KB." } }
                });

        user.ProfilePictureBase64 = command.Base64Image;
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
