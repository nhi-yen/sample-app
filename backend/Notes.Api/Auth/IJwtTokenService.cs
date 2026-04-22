using Notes.Api.Domain;

namespace Notes.Api.Auth;

public interface IJwtTokenService
{
    AuthResponse Issue(ApplicationUser user);
}