import { describe, it, expect } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Route, Routes } from "react-router-dom";
import { renderWithProviders } from "../test/renderWithProviders";
import { SEED_USER_EMAIL, SEED_USER_PASSWORD } from "../test/handlers";
import { LoginPage } from "./LoginPage";

function HomeProbe() {
  return <div data-testid="home-page">Home</div>;
}

describe("LoginPage", () => {
  it("renders the Sign in heading", async () => {
    renderWithProviders(<LoginPage />, {
      initialEntries: ["/login"],
      initialAuth: null,
    });

    expect(
      await screen.findByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
  });

  it("shows validation errors when submitting empty form", async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />, {
      initialEntries: ["/login"],
      initialAuth: null,
    });

    await user.click(await screen.findByRole("button", { name: /sign in/i }));

    expect(await screen.findByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/password is required/i)).toBeInTheDocument();
  });

  it("signs in with valid credentials and navigates home", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<HomeProbe />} />
      </Routes>,
      { initialEntries: ["/login"], initialAuth: null },
    );

    await user.type(await screen.findByLabelText(/email/i), SEED_USER_EMAIL);
    await user.type(screen.getByLabelText(/password/i), SEED_USER_PASSWORD);
    await user.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(screen.getByTestId("home-page")).toBeInTheDocument();
    });
  });

  it("shows an error message for invalid credentials", async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />, {
      initialEntries: ["/login"],
      initialAuth: null,
    });

    await user.type(await screen.findByLabelText(/email/i), SEED_USER_EMAIL);
    await user.type(screen.getByLabelText(/password/i), "wrong-password");
    await user.click(screen.getByRole("button", { name: /sign in/i }));

    expect(
      await screen.findByText(/invalid email or password/i),
    ).toBeInTheDocument();
  });
});
