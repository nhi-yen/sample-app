export const TOKEN_STORAGE_KEY = "notes.authToken";

export function readStoredToken(): string | null {
    try {
        return localStorage.getItem(TOKEN_STORAGE_KEY);
    } catch {
        return null;
    }
}

export function writeStoredToken(token: string): void {
    try {
        localStorage.setItem(TOKEN_STORAGE_KEY, token);
    } catch {
        // ignore
    }
}

export function clearStoredToken(): void {
    try {
        localStorage.removeItem(TOKEN_STORAGE_KEY);
    } catch {
        // ignore
    }
}
