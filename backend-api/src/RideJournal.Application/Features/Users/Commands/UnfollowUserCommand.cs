using MediatR;

namespace RideJournal.Application.Features.Users.Commands;

public record UnfollowUserCommand(string TargetUserId, string CurrentUserId) : IRequest<Unit>;
