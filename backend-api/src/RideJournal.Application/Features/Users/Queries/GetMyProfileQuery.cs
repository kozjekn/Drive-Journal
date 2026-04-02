using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Queries;

public record GetMyProfileQuery(string UserId) : IRequest<UserProfileDto>;
