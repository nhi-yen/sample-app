import { request } from './http'

export type UserDto = { id: string; email: string }
export type AuthResponse = {
    accessToken: string
    expiresAt: string
    user: UserDto
}

export function register(email: string, password: string): Promise<AuthResponse> {
    return request<AuthResponse>('/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
    })
}

export function login(email: string, password: string): Promise<AuthResponse> {
    return request<AuthResponse>('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
    })
}

export function me(): Promise<UserDto> {
    return request<UserDto>('/api/auth/me')
}
