using MediatR;

namespace DriveJournal.Application.Features.Users.Commands;

public record FollowUserCommand(string TargetUserId, string CurrentUserId) : IRequest<Unit>;
