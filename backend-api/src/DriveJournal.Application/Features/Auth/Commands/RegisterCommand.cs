using DriveJournal.Application.DTOs.Auth;
using MediatR;

namespace DriveJournal.Application.Features.Auth.Commands;

public record RegisterCommand(RegisterRequest Request) : IRequest<AuthResponse>;
