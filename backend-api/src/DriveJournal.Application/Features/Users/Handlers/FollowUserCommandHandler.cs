using DriveJournal.Application.Exceptions;
using DriveJournal.Application.Features.Users.Commands;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Users.Handlers;

public class FollowUserCommandHandler : IRequestHandler<FollowUserCommand, Unit>
{
    private readonly IUserRepository _userRepository;
    private readonly IFollowRepository _followRepository;

    public FollowUserCommandHandler(IUserRepository userRepository, IFollowRepository followRepository)
    {
        _userRepository = userRepository;
        _followRepository = followRepository;
    }

    public async Task<Unit> Handle(FollowUserCommand command, CancellationToken cancellationToken)
    {
        if (command.CurrentUserId == command.TargetUserId)
            throw new ConflictException("You cannot follow yourself.");

        var targetUser = await _userRepository.GetByIdAsync(command.TargetUserId);
        if (targetUser == null)
            throw new NotFoundException("User not found.");

        var existingFollow = await _followRepository.GetAsync(command.CurrentUserId, command.TargetUserId);
        if (existingFollow != null)
            throw new ConflictException("You are already following this user.");

        var follow = new Follow
        {
            Id = Guid.NewGuid().ToString(),
            FollowerId = command.CurrentUserId,
            FolloweeId = command.TargetUserId,
            CreatedAt = DateTime.UtcNow
        };

        await _followRepository.CreateAsync(follow);
        return Unit.Value;
    }
}
