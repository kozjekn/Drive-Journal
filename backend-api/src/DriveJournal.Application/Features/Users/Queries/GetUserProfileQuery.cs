using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Queries;

public record GetUserProfileQuery(string TargetUserId, string CurrentUserId) : IRequest<UserProfileDto>;
