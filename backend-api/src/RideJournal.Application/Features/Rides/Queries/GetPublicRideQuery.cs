using RideJournal.Application.DTOs.Rides;
using MediatR;

namespace RideJournal.Application.Features.Rides.Queries;

public record GetPublicRideQuery(string RideId) : IRequest<RideDto>;
