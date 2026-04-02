using DriveJournal.Application.DTOs.Rides;
using MediatR;

namespace DriveJournal.Application.Features.Rides.Queries;

public record GetPublicRideQuery(string RideId) : IRequest<RideDto>;
