import type { ReactElement, ReactNode } from "react";
import { render, type RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "../auth/AuthContext";
import { TOKEN_STORAGE_KEY } from "../auth/tokenStorage";
import type { UserDto } from "../api/auth";
import { SEED_USER_EMAIL, SEED_USER_ID, SEED_USER_TOKEN } from "./handlers";

type InitialAuth = { token: string; user: UserDto } | null;

type RenderWithProvidersOptions = Omit<RenderOptions, "wrapper"> & {
  initialEntries?: string[];
  path?: string;
  // - `undefined` (default): pre-seed as the default seed user
  // - `null`: unauthenticated (no token)
  // - explicit object: use custom token/user
  initialAuth?: InitialAuth;
};

// Tests should prefer `findBy*` assertions after render so the AuthProvider's
// `me()` bootstrap call has a chance to resolve before assertions run.
export function renderWithProviders(
  ui: ReactElement,
  {
    initialEntries = ["/"],
    path,
    initialAuth,
    ...renderOptions
  }: RenderWithProvidersOptions = {},
) {
  if (initialAuth === null) {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
  } else if (initialAuth === undefined) {
    localStorage.setItem(TOKEN_STORAGE_KEY, SEED_USER_TOKEN);
  } else {
    localStorage.setItem(TOKEN_STORAGE_KEY, initialAuth.token);
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });

  const content: ReactNode = path ? (
    <Routes>
      <Route path={path} element={ui} />
    </Routes>
  ) : (
    ui
  );

  const utils = render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={initialEntries}>
        <AuthProvider>{content}</AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>,
    renderOptions,
  );

  return { ...utils, queryClient };
}

export const seedUser: UserDto = {
  id: SEED_USER_ID,
  email: SEED_USER_EMAIL,
};
