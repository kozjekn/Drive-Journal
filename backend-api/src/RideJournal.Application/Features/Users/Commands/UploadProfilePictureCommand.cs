using RideJournal.Application.DTOs.Users;
using MediatR;

namespace RideJournal.Application.Features.Users.Commands;

public record UploadProfilePictureCommand(string Base64Image, string UserId) : IRequest<UserProfileDto>;
