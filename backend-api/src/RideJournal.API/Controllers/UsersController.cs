using RideJournal.API.Extensions;
using RideJournal.Application.DTOs.Users;
using RideJournal.Application.Features.Users.Commands;
using RideJournal.Application.Features.Users.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RideJournal.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserProfileDto>> GetMyProfile()
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new GetMyProfileQuery(userId));
        return Ok(result);
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserProfileDto>> UpdateMyProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new UpdateProfileCommand(request, userId));
        return Ok(result);
    }

    [HttpPost("me/profile-picture")]
    public async Task<ActionResult<UserProfileDto>> UploadProfilePicture([FromBody] UploadProfilePictureRequest request)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new UploadProfilePictureCommand(request.Base64Image, userId));
        return Ok(result);
    }

    [HttpGet("search")]
    public async Task<ActionResult<List<UserSearchResultDto>>> SearchUsers([FromQuery] string q, [FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new SearchUsersQuery(q, userId, skip, limit));
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserProfileDto>> GetUserProfile(string id)
    {
        var userId = User.GetUserId();
        var result = await _mediator.Send(new GetUserProfileQuery(id, userId));
        return Ok(result);
    }

    [HttpPost("{id}/follow")]
    public async Task<ActionResult> FollowUser(string id)
    {
        var userId = User.GetUserId();
        await _mediator.Send(new FollowUserCommand(id, userId));
        return NoContent();
    }

    [HttpDelete("{id}/follow")]
    public async Task<ActionResult> UnfollowUser(string id)
    {
        var userId = User.GetUserId();
        await _mediator.Send(new UnfollowUserCommand(id, userId));
        return NoContent();
    }

    [HttpGet("{id}/followers")]
    public async Task<ActionResult<List<FollowDto>>> GetFollowers(string id, [FromQuery] int skip = 0, [FromQuery] int limit = 50)
    {
        var result = await _mediator.Send(new GetFollowersQuery(id, skip, limit));
        return Ok(result);
    }

    [HttpGet("{id}/following")]
    public async Task<ActionResult<List<FollowDto>>> GetFollowing(string id, [FromQuery] int skip = 0, [FromQuery] int limit = 50)
    {
        var result = await _mediator.Send(new GetFollowingQuery(id, skip, limit));
        return Ok(result);
    }
}
