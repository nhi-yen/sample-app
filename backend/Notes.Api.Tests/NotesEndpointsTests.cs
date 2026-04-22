using System.Net;
using System.Net.Http.Json;

using FluentAssertions;

using Microsoft.AspNetCore.Mvc;

using Notes.Api.Contracts;

namespace Notes.Api.Tests;

public sealed class NotesEndpointsTests(NotesApiFactory factory) : IClassFixture<NotesApiFactory>
{
    private readonly NotesApiFactory _factory = factory;

    [Fact]
    public async Task Get_ReturnsEmptyList_OnFreshDatabase()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/notes");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var notes = await response.Content.ReadFromJsonAsync<List<NoteDto>>();
        notes.Should().NotBeNull();
        notes!.Should().BeEmpty();
    }

    [Fact]
    public async Task Post_WithValidBody_Returns201_WithLocationAndTimestamps()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();
        var request = new CreateNoteRequest("My title", "My content");

        var response = await client.PostAsJsonAsync("/api/notes", request);

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        response.Headers.Location.Should().NotBeNull();

        var dto = await response.Content.ReadFromJsonAsync<NoteDto>();
        dto.Should().NotBeNull();
        dto!.Id.Should().NotBe(Guid.Empty);
        dto.Title.Should().Be("My title");
        dto.Content.Should().Be("My content");
        dto.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(10));
        dto.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(10));
    }

    [Fact]
    public async Task Post_WithMissingTitle_Returns400ValidationProblem()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();
        var body = new { Title = "", Content = "some content" };

        var response = await client.PostAsJsonAsync("/api/notes", body);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>();
        problem.Should().NotBeNull();
        problem!.Errors.Should().ContainKey("Title");
    }

    [Fact]
    public async Task Get_WithUnknownId_Returns404()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();

        var response = await client.GetAsync($"/api/notes/{Guid.NewGuid()}");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Put_UpdatesExisting_And_Returns404ForUnknown()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();
        var created = await CreateNoteAsync(client, "original", "old content");

        var updateResp = await client.PutAsJsonAsync(
            $"/api/notes/{created.Id}",
            new UpdateNoteRequest("updated", "new content"));

        updateResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var updated = await updateResp.Content.ReadFromJsonAsync<NoteDto>();
        updated!.Title.Should().Be("updated");
        updated.Content.Should().Be("new content");
        updated.UpdatedAt.Should().BeOnOrAfter(created.UpdatedAt);

        var missingResp = await client.PutAsJsonAsync(
            $"/api/notes/{Guid.NewGuid()}",
            new UpdateNoteRequest("x", "y"));

        missingResp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Delete_RemovesExisting_And_Returns404AfterwardsAndForUnknown()
    {
        using var client = await _factory.CreateAuthenticatedClientAsync();
        var created = await CreateNoteAsync(client, "to-delete", "bye");

        var deleteResp = await client.DeleteAsync($"/api/notes/{created.Id}");
        deleteResp.StatusCode.Should().Be(HttpStatusCode.NoContent);

        var getResp = await client.GetAsync($"/api/notes/{created.Id}");
        getResp.StatusCode.Should().Be(HttpStatusCode.NotFound);

        var unknownResp = await client.DeleteAsync($"/api/notes/{Guid.NewGuid()}");
        unknownResp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    private static async Task<NoteDto> CreateNoteAsync(HttpClient client, string title, string content)
    {
        var response = await client.PostAsJsonAsync(
            "/api/notes",
            new CreateNoteRequest(title, content));
        response.EnsureSuccessStatusCode();
        var dto = await response.Content.ReadFromJsonAsync<NoteDto>();
        return dto!;
    }
}