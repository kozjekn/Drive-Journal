using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Commands;

public record SyncRidesCommand(SyncRidesRequest Request, string UserId) : IRequest<SyncRidesResponse>;
