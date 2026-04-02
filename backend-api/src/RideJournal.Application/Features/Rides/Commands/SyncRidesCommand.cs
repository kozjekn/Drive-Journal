using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Commands;

public record SyncRidesCommand(SyncRidesRequest Request, string UserId) : IRequest<SyncRidesResponse>;
