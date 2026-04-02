using DriveJournal.Application.DTOs.Rides;
using FluentValidation;

namespace DriveJournal.Application.Validators.Rides;

public class CreateRideRequestValidator : AbstractValidator<CreateRideRequest>
{
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
    }
}
