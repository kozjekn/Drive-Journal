using RideJournal.Application.DTOs.Users;
using RideJournal.Application.Features.Users.Queries;
using RideJournal.Domain.Interfaces;
using MediatR;

namespace RideJournal.Application.Features.Users.Handlers;

public class GetFollowersQueryHandler : IRequestHandler<GetFollowersQuery, List<FollowDto>>
{
    private readonly IFollowRepository _followRepository;
    private readonly IUserRepository _userRepository;

    public GetFollowersQueryHandler(IFollowRepository followRepository, IUserRepository userRepository)
    {
        _followRepository = followRepository;
        _userRepository = userRepository;
    }

    public async Task<List<FollowDto>> Handle(GetFollowersQuery query, CancellationToken cancellationToken)
    {
        var follows = await _followRepository.GetFollowersAsync(query.UserId, query.Skip, query.Limit);
        var results = new List<FollowDto>();

        foreach (var follow in follows)
        {
            var user = await _userRepository.GetByIdAsync(follow.FollowerId);
            if (user != null)
            {
                results.Add(new FollowDto
                {
                    UserId = user.Id,
                    DisplayName = user.DisplayName,
                    ProfilePictureBase64 = user.ProfilePictureBase64,
                    FollowedAt = follow.CreatedAt
                });
            }
        }

        return results;
    }
}
