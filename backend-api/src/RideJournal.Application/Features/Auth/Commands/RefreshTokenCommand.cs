using RideJournal.Application.DTOs.Auth;
using MediatR;

namespace RideJournal.Application.Features.Auth.Commands;

public record RefreshTokenCommand(string RefreshToken) : IRequest<AuthResponse>;
