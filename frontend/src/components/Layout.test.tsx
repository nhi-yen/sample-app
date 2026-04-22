import { describe, it, expect } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Route, Routes } from "react-router-dom";
import { renderWithProviders } from "../test/renderWithProviders";
import { TOKEN_STORAGE_KEY } from "../auth/tokenStorage";
import { SEED_USER_EMAIL } from "../test/handlers";
import { Layout } from "./Layout";

function HomeProbe() {
  return <div data-testid="home-page">Home</div>;
}

function LoginProbe() {
  return <div data-testid="login-page">Login</div>;
}

describe("Layout", () => {
  it("shows the authenticated user's email", async () => {
    renderWithProviders(
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomeProbe />} />
        </Route>
      </Routes>,
      { initialEntries: ["/"] },
    );

    expect(await screen.findByText(SEED_USER_EMAIL)).toBeInTheDocument();
  });

  it("signs out when the Sign out button is clicked", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomeProbe />} />
        </Route>
        <Route path="/login" element={<LoginProbe />} />
      </Routes>,
      { initialEntries: ["/"] },
    );

    await user.click(await screen.findByRole("button", { name: /sign out/i }));

    await waitFor(() => {
      expect(screen.getByTestId("login-page")).toBeInTheDocument();
    });
    expect(localStorage.getItem(TOKEN_STORAGE_KEY)).toBeNull();
    expect(screen.queryByText(SEED_USER_EMAIL)).not.toBeInTheDocument();
  });
});
