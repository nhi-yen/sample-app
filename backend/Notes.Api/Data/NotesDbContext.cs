using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

using Notes.Api.Domain;

namespace Notes.Api.Data;

public sealed class NotesDbContext(DbContextOptions<NotesDbContext> options) : IdentityDbContext<ApplicationUser>(options)
{
    public DbSet<Note> Notes => Set<Note>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(NotesDbContext).Assembly);
    }
}