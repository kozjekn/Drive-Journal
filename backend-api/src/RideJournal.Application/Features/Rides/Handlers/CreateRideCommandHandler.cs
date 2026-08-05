using AutoMapper;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Exceptions;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Domain.Entities;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Rides.Handlers;

public class CreateRideCommandHandler : IRequestHandler<CreateRideCommand, CreateRideResult>
{
    private readonly IRideRepository _rideRepository;
    private readonly IMapper _mapper;

    public CreateRideCommandHandler(IRideRepository rideRepository, IMapper mapper)
    {
        _rideRepository = rideRepository;
        _mapper = mapper;
    }

    /// <remarks>
    /// Idempotent by ride id. Clients generate the id, so a request that timed out
    /// after the server had already committed used to be retried into a
    /// duplicate-key MongoWriteException surfacing as a 500. Replaying the same id
    /// now returns the stored ride instead.
    /// </remarks>
    public async Task<CreateRideResult> Handle(CreateRideCommand command, CancellationToken cancellationToken)
    {
        if (!string.IsNullOrEmpty(command.Request.Id))
        {
            var existing = await _rideRepository.GetByIdIncludingDeletedAsync(command.Request.Id);
            if (existing != null)
            {
                if (existing.UserId != command.UserId)
                    throw new ConflictException($"Ride with id '{command.Request.Id}' already exists.");

                // Same owner replaying the same id: hand back what we already have.
                return new CreateRideResult(_mapper.Map<RideDto>(existing), Created: false);
            }
        }

        var ride = _mapper.Map<Ride>(command.Request);
        ride.UserId = command.UserId;
        ride.CreatedAt = DateTime.UtcNow;
        ride.UpdatedAt = DateTime.UtcNow;

        if (string.IsNullOrEmpty(ride.Id))
            ride.Id = Guid.NewGuid().ToString();

        try
        {
            await _rideRepository.CreateAsync(ride);
        }
        catch (ConflictException)
        {
            // Lost a race against a concurrent create of the same id. Re-read and
            // return it rather than failing a request that got the intended result.
            var raced = await _rideRepository.GetByIdIncludingDeletedAsync(ride.Id);
            if (raced == null || raced.UserId != command.UserId) throw;
            return new CreateRideResult(_mapper.Map<RideDto>(raced), Created: false);
        }

        return new CreateRideResult(_mapper.Map<RideDto>(ride), Created: true);
    }
}
