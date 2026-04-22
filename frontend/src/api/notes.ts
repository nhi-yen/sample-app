import { request } from './http'

export type Note = {
    id: string
    title: string
    content: string
    createdAt: string
    updatedAt: string
}

export type NoteInput = {
    title: string
    content: string
}

export function listNotes(): Promise<Note[]> {
    return request<Note[]>('/api/notes')
}

export function getNote(id: string): Promise<Note> {
    return request<Note>(`/api/notes/${id}`)
}

export function createNote(input: NoteInput): Promise<Note> {
    return request<Note>('/api/notes', {
        method: 'POST',
        body: JSON.stringify(input),
    })
}

export function updateNote(id: string, input: NoteInput): Promise<Note> {
    return request<Note>(`/api/notes/${id}`, {
        method: 'PUT',
        body: JSON.stringify(input),
    })
}

export function deleteNote(id: string): Promise<void> {
    return request<void>(`/api/notes/${id}`, { method: 'DELETE' })
}
