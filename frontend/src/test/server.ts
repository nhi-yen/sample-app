import { setupServer } from 'msw/node'
import {
    defaultAuthStore,
    defaultSeed,
    handlers,
    notesStore,
    seedAuthStore,
} from './handlers'

export const server = setupServer(...handlers)

export function resetNotesStore(): void {
    notesStore.reset(defaultSeed)
}

export function resetAuthStore(): void {
    seedAuthStore(defaultAuthStore)
}

export { notesStore, defaultSeed, defaultAuthStore }
