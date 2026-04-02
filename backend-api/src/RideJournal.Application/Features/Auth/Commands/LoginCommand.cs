using RideJournal.Application.DTOs.Auth;
using MediatR;

namespace RideJournal.Application.Features.Auth.Commands;

public record LoginCommand(LoginRequest Request) : IRequest<AuthResponse>;
