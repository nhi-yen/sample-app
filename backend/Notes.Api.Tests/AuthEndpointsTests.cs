using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

using FluentAssertions;

using Notes.Api.Auth;

namespace Notes.Api.Tests;

public sealed class AuthEndpointsTests(NotesApiFactory factory) : IClassFixture<NotesApiFactory>
{
    private readonly NotesApiFactory _factory = factory;

    [Fact]
    public async Task Register_WithValidBody_Returns200_WithTokenAndUser()
    {
        using var client = _factory.CreateClient();
        var email = $"user-{Guid.NewGuid():N}@test.local";

        var response = await client.PostAsJsonAsync("/api/auth/register",
            new { email, password = "Password123!" });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        auth.Should().NotBeNull();
        auth!.AccessToken.Should().NotBeNullOrWhiteSpace();
        auth.User.Email.Should().Be(email);
        auth.User.Id.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task Register_WithDuplicateEmail_Returns400()
    {
        using var client = _factory.CreateClient();
        var email = $"dup-{Guid.NewGuid():N}@test.local";

        var first = await client.PostAsJsonAsync("/api/auth/register",
            new { email, password = "Password123!" });
        first.EnsureSuccessStatusCode();

        var second = await client.PostAsJsonAsync("/api/auth/register",
            new { email, password = "Password123!" });

        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Theory]
    [InlineData("not-an-email", "Password123!")]
    [InlineData("ok@test.local", "short")]
    public async Task Register_WithInvalidInput_Returns400(string email, string password)
    {
        using var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new { email, password });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Login_WithValidCredentials_Returns200_WithToken()
    {
        using var client = _factory.CreateClient();
        var email = $"login-{Guid.NewGuid():N}@test.local";
        const string password = "Password123!";

        (await client.PostAsJsonAsync("/api/auth/register", new { email, password }))
            .EnsureSuccessStatusCode();

        var response = await client.PostAsJsonAsync("/api/auth/login", new { email, password });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        auth!.AccessToken.Should().NotBeNullOrWhiteSpace();
        auth.User.Email.Should().Be(email);
    }

    [Fact]
    public async Task Login_WithWrongPassword_Returns401()
    {
        using var client = _factory.CreateClient();
        var email = $"wrong-{Guid.NewGuid():N}@test.local";

        (await client.PostAsJsonAsync("/api/auth/register",
            new { email, password = "Password123!" })).EnsureSuccessStatusCode();

        var response = await client.PostAsJsonAsync("/api/auth/login",
            new { email, password = "WrongPassword1!" });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Me_WithoutToken_Returns401()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/auth/me");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Me_WithToken_ReturnsUser()
    {
        var email = $"me-{Guid.NewGuid():N}@test.local";
        using var client = await _factory.CreateAuthenticatedClientAsync(email);

        var response = await client.GetAsync("/api/auth/me");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var user = await response.Content.ReadFromJsonAsync<UserDto>();
        user.Should().NotBeNull();
        user!.Email.Should().Be(email);
        user.Id.Should().NotBeNullOrWhiteSpace();
    }
}