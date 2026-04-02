using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Queries;

public record GetMyProfileQuery(string UserId) : IRequest<UserProfileDto>;
