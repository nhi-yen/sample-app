import { createContext } from "react";
import type { UserDto } from "../api/auth";

export type AuthState =
    | { status: "loading" }
    | { status: "unauthenticated" }
    | { status: "authenticated"; user: UserDto; token: string };

export type AuthContextValue = AuthState & {
    login: (email: string, password: string) => Promise<void>;
    register: (email: string, password: string) => Promise<void>;
    logout: () => void;
};

export const AuthContext = createContext<AuthContextValue | null>(null);
