using System.Net.Http.Headers;
using System.Net.Http.Json;

using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

using Notes.Api.Auth;

namespace Notes.Api.Tests;

public sealed class NotesApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly string _dbPath = Path.Combine(Path.GetTempPath(), $"notes-tests-{Guid.NewGuid():N}.db");

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Database:Provider"] = "Sqlite",
                ["ConnectionStrings:Sqlite"] = $"Data Source={_dbPath}",
                ["Jwt:Issuer"] = "notes-api-tests",
                ["Jwt:Audience"] = "notes-api-tests",
                ["Jwt:SigningKey"] = "test-signing-key-test-signing-key-test-0123",
                ["Jwt:AccessTokenLifetimeMinutes"] = "60"
            });
        });
    }

    public async Task<HttpClient> CreateAuthenticatedClientAsync(
        string? email = null,
        string password = "Password123!")
    {
        var (client, _, _) = await CreateAuthenticatedClientWithUserAsync(email, password);
        return client;
    }

    public async Task<(HttpClient Client, string UserId, string Email)> CreateAuthenticatedClientWithUserAsync(
        string? email = null,
        string password = "Password123!")
    {
        email ??= $"user-{Guid.NewGuid():N}@test.local";
        var client = CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new { email, password });
        response.EnsureSuccessStatusCode();

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>()
            ?? throw new InvalidOperationException("Failed to read AuthResponse");

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        return (client, auth.User.Id, auth.User.Email);
    }

    public Task InitializeAsync() => Task.CompletedTask;

    public new Task DisposeAsync()
    {
        base.Dispose();
        if (File.Exists(_dbPath))
        {
            try { File.Delete(_dbPath); } catch { /* best-effort */ }
        }
        return Task.CompletedTask;
    }
}