using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Users.Commands;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Users.Handlers;

public class UnfollowUserCommandHandler : IRequestHandler<UnfollowUserCommand, Unit>
{
    private readonly IFollowRepository _followRepository;

    public UnfollowUserCommandHandler(IFollowRepository followRepository)
    {
        _followRepository = followRepository;
    }

    public async Task<Unit> Handle(UnfollowUserCommand command, CancellationToken cancellationToken)
    {
        var follow = await _followRepository.GetAsync(command.CurrentUserId, command.TargetUserId);
        if (follow == null)
            throw new NotFoundException("You are not following this user.");

        await _followRepository.DeleteAsync(command.CurrentUserId, command.TargetUserId);
        return Unit.Value;
    }
}
