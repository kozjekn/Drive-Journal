using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Commands;

public record UpdateProfileCommand(UpdateProfileRequest Request, string UserId) : IRequest<UserProfileDto>;
