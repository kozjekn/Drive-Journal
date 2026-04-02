using DriveJournal.Application.DTOs.Auth;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Commands;

public record RefreshTokenCommand(string RefreshToken) : IRequest<AuthResponse>;
