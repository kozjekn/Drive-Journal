using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class SyncRidesCommandHandler : IRequestHandler<SyncRidesCommand, SyncRidesResponse>
{
    /// <summary>
    /// Rides returned per pull. Route points are embedded, so a long ride is
    /// ~1.5 MB of JSON; this keeps a page well inside the request/response limits.
    /// </summary>
    private const int MaxPullBatch = 50;

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

        // 1. Upsert client rides — conflicts resolved by the client's UpdatedAt.
        foreach (var clientRide in request.Rides)
        {
            // Tombstone-aware: a lookup that hid deleted rides would report "new"
            // and let a stale client resurrect a ride it had already deleted.
            var serverRide = await _rideRepository.GetByIdIncludingDeletedAsync(clientRide.Id);

            if (serverRide == null)
            {
                var newRide = _mapper.Map<Ride>(clientRide);
                // Never trust clientRide.UserId — the ride belongs to the caller.
                newRide.UserId = command.UserId;
                newRide.UpdatedAt = clientRide.UpdatedAt;
                // Clients don't send CreatedAt, which used to persist as
                // DateTime.MinValue (year 0001) on every synced ride.
                newRide.CreatedAt = clientRide.CreatedAt == default
                    ? syncTime
                    : clientRide.CreatedAt;
                newRide.DeletedAt = null;
                await _rideRepository.CreateAsync(newRide);
            }
            else if (serverRide.UserId == command.UserId)
            {
                // A delete wins over an older client edit.
                if (serverRide.DeletedAt != null && clientRide.UpdatedAt <= serverRide.UpdatedAt)
                    continue;

                if (clientRide.UpdatedAt > serverRide.UpdatedAt)
                {
                    var updatedRide = _mapper.Map<Ride>(clientRide);
                    updatedRide.UserId = command.UserId;
                    updatedRide.UpdatedAt = clientRide.UpdatedAt;
                    updatedRide.CreatedAt = serverRide.CreatedAt; // preserve
                    updatedRide.DeletedAt = serverRide.DeletedAt;
                    await _rideRepository.UpsertAsync(updatedRide);
                }
            }
            // Someone else's ride id: ignore silently rather than leaking its
            // existence or overwriting it.
        }

        // 2. Pull server rides written after lastSyncAt, excluding what the client
        //    just sent. Ask for one extra to detect truncation.
        var serverUpdated = await _rideRepository.GetUpdatedAfterAsync(
            command.UserId, lastSync, clientRideIds, MaxPullBatch + 1);

        var hasMore = serverUpdated.Count > MaxPullBatch;
        if (hasMore)
        {
            serverUpdated = serverUpdated.Take(MaxPullBatch).ToList();
        }

        // When truncated the cursor must be the last returned ride's server
        // timestamp, not syncTime — otherwise the next page would skip everything
        // written between the two.
        var cursor = hasMore
            ? serverUpdated[^1].ServerUpdatedAt
            : syncTime;

        var deletedRideIds = await _rideRepository.GetDeletedAfterAsync(command.UserId, lastSync);

        return new SyncRidesResponse
        {
            SyncedAt = cursor,
            UpdatedRides = _mapper.Map<List<RideDto>>(serverUpdated),
            DeletedRideIds = deletedRideIds,
            HasMore = hasMore
        };
    }
}
