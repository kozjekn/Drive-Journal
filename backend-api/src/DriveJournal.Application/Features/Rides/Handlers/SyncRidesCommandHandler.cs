using AutoMapper;
using DriveJournal.Application.DTOs.Rides;
using DriveJournal.Application.Features.Rides.Commands;
using DriveJournal.Domain.Entities;
using DriveJournal.Domain.Interfaces;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Handlers;

public class SyncRidesCommandHandler : IRequestHandler<SyncRidesCommand, SyncRidesResponse>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public SyncRidesCommandHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    public async Task<SyncRidesResponse> Handle(SyncRidesCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;
        var syncTime = DateTime.UtcNow;
        var lastSync = request.LastSyncAt ?? DateTime.MinValue;
        var clientRideIds = request.Rides.Select(r => r.Id).ToList();

        // 1. Upsert client rides — resolve conflicts by updatedAt
        foreach (var clientRide in request.Rides)
        {
            var serverRide = await _rideRepository.GetByIdAsync(clientRide.Id);

            if (serverRide == null)
            {
                // New ride from client — create on server
                var newRide = _mapper.Map<Ride>(clientRide);
                newRide.UserId = command.UserId;
                newRide.UpdatedAt = clientRide.UpdatedAt;
                await _rideRepository.CreateAsync(newRide);
            }
            else if (serverRide.UserId == command.UserId)
            {
                // Existing ride — client wins if updatedAt is later
                if (clientRide.UpdatedAt > serverRide.UpdatedAt)
                {
                    var updatedRide = _mapper.Map<Ride>(clientRide);
                    updatedRide.UserId = command.UserId;
                    updatedRide.UpdatedAt = clientRide.UpdatedAt;
                    await _rideRepository.UpsertAsync(updatedRide);
                }
            }
        }

        // 2. Get server rides updated after lastSyncAt, excluding rides client just sent
        var serverUpdated = await _rideRepository.GetUpdatedAfterAsync(
            command.UserId, lastSync, clientRideIds);

        return new SyncRidesResponse
        {
            SyncedAt = syncTime,
            UpdatedRides = _mapper.Map<List<RideDto>>(serverUpdated),
            DeletedRideIds = new List<string>()
        };
    }
}
