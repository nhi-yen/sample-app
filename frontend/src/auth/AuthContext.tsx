import { useCallback, useEffect, useState, type ReactNode } from "react";
import { useQueryClient } from "@tanstack/react-query";
import * as authApi from "../api/auth";
import { setAuthHooks } from "../api/http";
import {
  AuthContext,
  type AuthContextValue,
  type AuthState,
} from "./authContextInternal";
import {
  clearStoredToken,
  readStoredToken,
  writeStoredToken,
} from "./tokenStorage";

// Module-level state keeps the HTTP layer's view of the current token and the
// unauthorized handler in sync with the provider, without requiring refs to be
// written during render. `setAuthHooks` is called once at module load so the
// first outbound request from any child carries whatever token the provider
// writes synchronously during its `useState` initializer.
let currentToken: string | null = null;
let currentOnUnauthorized: () => void = () => {};

setAuthHooks({
  getToken: () => currentToken,
  onUnauthorized: () => currentOnUnauthorized(),
});

type AuthProviderProps = {
  children: ReactNode;
};

export function AuthProvider({ children }: AuthProviderProps) {
  const queryClient = useQueryClient();

  // Initializer runs synchronously before children render, so the module-level
  // token is populated before any child can fire a request.
  const [state, setState] = useState<AuthState>(() => {
    const stored = readStoredToken();
    currentToken = stored;
    return stored ? { status: "loading" } : { status: "unauthenticated" };
  });

  const handleUnauthorized = useCallback(() => {
    clearStoredToken();
    currentToken = null;
    setState({ status: "unauthenticated" });
    queryClient.clear();
  }, [queryClient]);

  useEffect(() => {
    currentOnUnauthorized = handleUnauthorized;
  }, [handleUnauthorized]);

  // Bootstrap: if we started with a stored token, verify it with /api/auth/me.
  useEffect(() => {
    if (state.status !== "loading") return;
    const bootstrapToken = currentToken;
    if (!bootstrapToken) return;
    let cancelled = false;
    authApi
      .me()
      .then((user) => {
        if (cancelled) return;
        setState({ status: "authenticated", user, token: bootstrapToken });
      })
      .catch(() => {
        if (cancelled) return;
        clearStoredToken();
        currentToken = null;
        setState({ status: "unauthenticated" });
      });
    return () => {
      cancelled = true;
    };
    // Bootstrap should only run once on mount.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const response = await authApi.login(email, password);
    writeStoredToken(response.accessToken);
    currentToken = response.accessToken;
    setState({
      status: "authenticated",
      user: response.user,
      token: response.accessToken,
    });
  }, []);

  const register = useCallback(async (email: string, password: string) => {
    const response = await authApi.register(email, password);
    writeStoredToken(response.accessToken);
    currentToken = response.accessToken;
    setState({
      status: "authenticated",
      user: response.user,
      token: response.accessToken,
    });
  }, []);

  const logout = useCallback(() => {
    clearStoredToken();
    currentToken = null;
    setState({ status: "unauthenticated" });
    queryClient.clear();
  }, [queryClient]);

  const value: AuthContextValue = { ...state, login, register, logout };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
