using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Commands;

public record UpdateProfileCommand(UpdateProfileRequest Request, string UserId) : IRequest<UserProfileDto>;
