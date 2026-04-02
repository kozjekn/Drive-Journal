using DriveJournal.Application.DTOs.Users;
using MediatR;

namespace DriveJournal.Application.Features.Users.Commands;

public record UploadProfilePictureCommand(string Base64Image, string UserId) : IRequest<UserProfileDto>;
