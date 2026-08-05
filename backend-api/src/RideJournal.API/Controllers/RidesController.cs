using RideJournal.API.Extensions;
using RideJournal.Application.DTOs.Rides;
using RideJournal.Application.Features.Rides.Commands;
using RideJournal.Application.Features.Rides.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RideJournal.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RidesController : ControllerBase
{
    private readonly IMediator _mediator;

    public RidesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<ActionResult<List<RideDto>>> GetMyRides()
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new GetUserRidesQuery(userId));
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<RideDto>> GetRide(string id)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new GetRideByIdQuery(id, userId));
        return Ok(result);
    }

    /// <remarks>
    /// Idempotent: replaying a client-generated id the caller already owns returns
    /// 200 with the stored ride instead of failing, so an upload retried after an
    /// ambiguous timeout is safe.
    /// </remarks>
    [HttpPost]
    public async Task<ActionResult<RideDto>> CreateRide([FromBody] CreateRideRequest request)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new CreateRideCommand(request, userId));
        return result.Created
            ? CreatedAtAction(nameof(GetRide), new { id = result.Ride.Id }, result.Ride)
            : Ok(result.Ride);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<RideDto>> UpdateRide(string id, [FromBody] UpdateRideRequest request)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new UpdateRideCommand(id, request, userId));
        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteRide(string id)
    {
        var userId = User.GetUserId();
        await _mediator.Send(new DeleteRideCommand(id, userId));
        return NoContent();
    }

    [HttpPost("sync")]
    public async Task<ActionResult<SyncRidesResponse>> SyncRides([FromBody] SyncRidesRequest request)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new SyncRidesCommand(request, userId));
        return Ok(result);
    }

    [HttpGet("feed")]
    public async Task<ActionResult<List<RideDto>>> GetFeed([FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new GetFeedRidesQuery(userId, skip, limit));
        return Ok(result);
    }

    [HttpGet("user/{userId}/public")]
    public async Task<ActionResult<List<RideDto>>> GetUserPublicRides(
        string userId, [FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        var result = await _mediator.Send(new GetPublicRidesByUserQuery(userId, skip, limit));
        return Ok(result);
    }

    [HttpGet("public/{id}")]
    [AllowAnonymous]
    public async Task<ActionResult<RideDto>> GetPublicRide(string id)
    {
        var result = await _mediator.Send(new GetPublicRideQuery(id));
        return Ok(result);
    }
}
