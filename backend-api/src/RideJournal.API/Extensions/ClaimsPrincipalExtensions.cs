using System.Security.Claims;
using RideJournal.Application.Exceptions;

namespace RideJournal.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static string GetUserId(this ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub")
            ?? throw new UnauthorizedException("User ID not found in claims.");
    }
}
