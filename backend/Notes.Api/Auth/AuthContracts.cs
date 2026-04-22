using System.ComponentModel.DataAnnotations;

namespace Notes.Api.Auth;

public sealed record RegisterRequest(
    [Required][EmailAddress] string Email,
    [Required][StringLength(256, MinimumLength = 8)] string Password);

public sealed record LoginRequest(
    [Required][EmailAddress] string Email,
    [Required] string Password);

public sealed record UserDto(string Id, string Email);

public sealed record AuthResponse(string AccessToken, DateTimeOffset ExpiresAt, UserDto User);