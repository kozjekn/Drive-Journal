using RideJournal.Application.DTOs.Rides;
using FluentValidation;

namespace RideJournal.Application.Validators.Rides;

public class CreateRideRequestValidator : AbstractValidator<CreateRideRequest>
{
    /// <summary>
    /// Route points are embedded in the ride document, so an unbounded list is an
    /// unbounded request body. 200k points is ~55 hours at 1 Hz — generous, but finite.
    /// </summary>
    public const int MaxRoutePoints = 200_000;

    public CreateRideRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Ride name is required.")
            .MaximumLength(100).WithMessage("Ride name must not exceed 100 characters.");

        RuleFor(x => x.DistanceMeters)
            .GreaterThanOrEqualTo(0).WithMessage("Distance must be non-negative.");

        RuleFor(x => x.DurationMs)
            .GreaterThanOrEqualTo(0).WithMessage("Duration must be non-negative.");

        RuleFor(x => x.StartTime)
            .NotEmpty().WithMessage("Start time is required.");

        RuleFor(x => x.Visibility)
            .IsInEnum().WithMessage("Invalid visibility value.");

        RuleFor(x => x.RoutePoints)
            .Must(points => points == null || points.Count <= MaxRoutePoints)
            .WithMessage($"A ride may contain at most {MaxRoutePoints} route points.");
    }
}
