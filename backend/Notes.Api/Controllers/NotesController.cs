using System.Security.Claims;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using Notes.Api.Contracts;
using Notes.Api.Data;
using Notes.Api.Domain;

namespace Notes.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class NotesController(NotesDbContext db) : ControllerBase
{
    private string CurrentUserId =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ?? throw new UnauthorizedAccessException();

    [HttpGet]
    [ProducesResponseType<List<NoteDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<List<NoteDto>>> GetAll(CancellationToken ct)
    {
        var userId = CurrentUserId;
        var notes = await db.Notes
            .AsNoTracking()
            .Where(n => n.OwnerId == userId)
            .OrderByDescending(n => n.UpdatedAt)
            .Select(n => new NoteDto(n.Id, n.Title, n.Content, n.CreatedAt, n.UpdatedAt))
            .ToListAsync(ct);

        return Ok(notes);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType<NoteDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<NoteDto>> GetById(Guid id, CancellationToken ct)
    {
        var userId = CurrentUserId;
        var note = await db.Notes
            .AsNoTracking()
            .Where(n => n.Id == id && n.OwnerId == userId)
            .Select(n => new NoteDto(n.Id, n.Title, n.Content, n.CreatedAt, n.UpdatedAt))
            .FirstOrDefaultAsync(ct);

        return note is null ? NotFound() : Ok(note);
    }

    [HttpPost]
    [ProducesResponseType<NoteDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<NoteDto>> Create(CreateNoteRequest request, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var note = new Note
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Content = request.Content,
            CreatedAt = now,
            UpdatedAt = now,
            OwnerId = CurrentUserId
        };

        db.Notes.Add(note);
        await db.SaveChangesAsync(ct);

        var dto = new NoteDto(note.Id, note.Title, note.Content, note.CreatedAt, note.UpdatedAt);
        return CreatedAtAction(nameof(GetById), new { id = note.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType<NoteDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<NoteDto>> Update(Guid id, UpdateNoteRequest request, CancellationToken ct)
    {
        var userId = CurrentUserId;
        var note = await db.Notes.FirstOrDefaultAsync(n => n.Id == id && n.OwnerId == userId, ct);
        if (note is null)
        {
            return NotFound();
        }

        note.Title = request.Title;
        note.Content = request.Content;
        note.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);

        return Ok(new NoteDto(note.Id, note.Title, note.Content, note.CreatedAt, note.UpdatedAt));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var userId = CurrentUserId;
        var note = await db.Notes.FirstOrDefaultAsync(n => n.Id == id && n.OwnerId == userId, ct);
        if (note is null)
        {
            return NotFound();
        }

        db.Notes.Remove(note);
        await db.SaveChangesAsync(ct);

        return NoContent();
    }
}