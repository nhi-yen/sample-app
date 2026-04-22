import { describe, it, expect } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Route, Routes } from "react-router-dom";
import { renderWithProviders } from "../test/renderWithProviders";
import { defaultAuthStore, SEED_USER_EMAIL } from "../test/handlers";
import { RegisterPage } from "./RegisterPage";

function HomeProbe() {
  return <div data-testid="home-page">Home</div>;
}

describe("RegisterPage", () => {
  it("registers a new user and navigates home", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <Routes>
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/" element={<HomeProbe />} />
      </Routes>,
      { initialEntries: ["/register"], initialAuth: null },
    );

    await user.type(
      await screen.findByLabelText(/email/i),
      "new-user@test.local",
    );
    await user.type(screen.getByLabelText(/password/i), "Password123!");
    await user.click(screen.getByRole("button", { name: /create account/i }));

    await waitFor(() => {
      expect(screen.getByTestId("home-page")).toBeInTheDocument();
    });

    expect(defaultAuthStore.users.has("new-user@test.local")).toBe(true);
  });

  it("shows a client-side error for a short password", async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />, {
      initialEntries: ["/register"],
      initialAuth: null,
    });

    await user.type(
      await screen.findByLabelText(/email/i),
      "someone@test.local",
    );
    await user.type(screen.getByLabelText(/password/i), "short");
    await user.click(screen.getByRole("button", { name: /create account/i }));

    expect(
      await screen.findByText(/at least 8 characters/i),
    ).toBeInTheDocument();
  });

  it("shows a server error when the email is already taken", async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />, {
      initialEntries: ["/register"],
      initialAuth: null,
    });

    await user.type(await screen.findByLabelText(/email/i), SEED_USER_EMAIL);
    await user.type(screen.getByLabelText(/password/i), "Password123!");
    await user.click(screen.getByRole("button", { name: /create account/i }));

    expect(await screen.findByText(/already registered/i)).toBeInTheDocument();
  });
});
