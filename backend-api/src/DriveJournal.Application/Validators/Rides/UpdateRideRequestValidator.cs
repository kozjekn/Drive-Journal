using DriveJournal.Application.DTOs.Rides;
using FluentValidation;

namespace DriveJournal.Application.Validators.Rides;

public class UpdateRideRequestValidator : AbstractValidator<UpdateRideRequest>
{
    public UpdateRideRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Ride name is required.")
            .MaximumLength(100).WithMessage("Ride name must not exceed 100 characters.");

        RuleFor(x => x.Visibility)
            .IsInEnum().WithMessage("Invalid visibility value.");
    }
}
