import '@testing-library/jest-dom/vitest'
import { afterAll, afterEach, beforeAll, beforeEach } from 'vitest'
import { server, resetNotesStore, resetAuthStore } from './server'
import { TOKEN_STORAGE_KEY } from '../auth/tokenStorage'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
beforeEach(() => {
    resetAuthStore()
    resetNotesStore()
    localStorage.removeItem(TOKEN_STORAGE_KEY)
})
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
