using DriveJournal.Application.DTOs.Auth;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Commands;

public record GoogleAuthCommand(string IdToken) : IRequest<AuthResponse>;
