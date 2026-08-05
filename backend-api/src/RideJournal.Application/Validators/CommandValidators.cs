using FluentValidation;
using RideJournal.Application.Features.Auth.Commands;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Application.Features.Users.Commands;
using RideJournal.Application.Validators.Auth;
using RideJournal.Application.Validators.Rides;
using RideJournal.Application.Validators.Users;

namespace RideJournal.Application.Validators;

// ValidationBehavior<TRequest, TResponse> resolves IValidator<TRequest> where
// TRequest is the MediatR *command*. Every validator in this assembly targets the
// inner request DTO instead, so the behaviour never found one and validation did
// not run at all at runtime — an empty ride name or a negative distance was
// accepted with a 201.
//
// These thin wrappers bridge command -> request so the existing DTO validators
// (and their unit tests) keep working unchanged. AddValidatorsFromAssembly picks
// them up with no DI change.

public class CreateRideCommandValidator : AbstractValidator<CreateRideCommand>
{
    public CreateRideCommandValidator()
    {
        RuleFor(x => x.Request).NotNull().SetValidator(new CreateRideRequestValidator());
    }
}

public class UpdateRideCommandValidator : AbstractValidator<UpdateRideCommand>
{
    public UpdateRideCommandValidator()
    {
        RuleFor(x => x.Request).NotNull().SetValidator(new UpdateRideRequestValidator());
    }
}

public class SyncRidesCommandValidator : AbstractValidator<SyncRidesCommand>
{
    /// <summary>Matches the client's push chunk cap; keeps one body bounded.</summary>
    public const int MaxRidesPerSync = 50;

    public SyncRidesCommandValidator()
    {
        RuleFor(x => x.Request).NotNull();

        RuleFor(x => x.Request.Rides)
            .Must(rides => rides == null || rides.Count <= MaxRidesPerSync)
            .WithMessage($"A sync request may contain at most {MaxRidesPerSync} rides.");

        RuleForEach(x => x.Request.Rides).ChildRules(ride =>
        {
            ride.RuleFor(r => r.RoutePoints)
                .Must(points => points == null || points.Count <= CreateRideRequestValidator.MaxRoutePoints)
                .WithMessage(
                    $"A ride may contain at most {CreateRideRequestValidator.MaxRoutePoints} route points.");
        });
    }
}

public class LoginCommandValidator : AbstractValidator<LoginCommand>
{
    public LoginCommandValidator()
    {
        RuleFor(x => x.Request).NotNull().SetValidator(new LoginRequestValidator());
    }
}

public class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(x => x.Request).NotNull().SetValidator(new RegisterRequestValidator());
    }
}

public class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    public UpdateProfileCommandValidator()
    {
        RuleFor(x => x.Request).NotNull().SetValidator(new UpdateProfileRequestValidator());
    }
}
