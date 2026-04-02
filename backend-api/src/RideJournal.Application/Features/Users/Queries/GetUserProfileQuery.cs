using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Queries;

public record GetUserProfileQuery(string TargetUserId, string CurrentUserId) : IRequest<UserProfileDto>;
