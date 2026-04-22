using System.Net;
using System.Net.Http.Json;

using FluentAssertions;

using Notes.Api.Contracts;

namespace Notes.Api.Tests;

public sealed class NotesAuthorizationTests(NotesApiFactory factory) : IClassFixture<NotesApiFactory>
{
    private readonly NotesApiFactory _factory = factory;

    [Fact]
    public async Task GetAll_WithoutToken_Returns401()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/notes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Notes_AreScopedToOwner()
    {
        var (clientA, _, _) = await _factory.CreateAuthenticatedClientWithUserAsync();
        var (clientB, _, _) = await _factory.CreateAuthenticatedClientWithUserAsync();

        using (clientA)
        using (clientB)
        {
            var createResp = await clientA.PostAsJsonAsync("/api/notes",
                new CreateNoteRequest("A's note", "secret"));
            createResp.EnsureSuccessStatusCode();
            var created = await createResp.Content.ReadFromJsonAsync<NoteDto>();
            created.Should().NotBeNull();

            var listResp = await clientB.GetAsync("/api/notes");
            listResp.StatusCode.Should().Be(HttpStatusCode.OK);
            var bList = await listResp.Content.ReadFromJsonAsync<List<NoteDto>>();
            bList.Should().NotBeNull();
            bList!.Should().BeEmpty();

            var byIdResp = await clientB.GetAsync($"/api/notes/{created!.Id}");
            byIdResp.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }
    }
}