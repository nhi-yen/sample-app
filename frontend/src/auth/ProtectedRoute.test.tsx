import { describe, it, expect } from "vitest";
import { screen } from "@testing-library/react";
import { Route, Routes } from "react-router-dom";
import { renderWithProviders } from "../test/renderWithProviders";
import { ProtectedRoute } from "./ProtectedRoute";

function LoginProbe() {
  return <div data-testid="login-page">Login</div>;
}

function ProtectedContent() {
  return <div data-testid="protected-content">Secret</div>;
}

describe("ProtectedRoute", () => {
  it("redirects to /login when unauthenticated", async () => {
    renderWithProviders(
      <Routes>
        <Route path="/login" element={<LoginProbe />} />
        <Route element={<ProtectedRoute />}>
          <Route path="/" element={<ProtectedContent />} />
        </Route>
      </Routes>,
      { initialEntries: ["/"], initialAuth: null },
    );

    expect(await screen.findByTestId("login-page")).toBeInTheDocument();
    expect(screen.queryByTestId("protected-content")).not.toBeInTheDocument();
  });

  it("renders child routes when authenticated", async () => {
    renderWithProviders(
      <Routes>
        <Route path="/login" element={<LoginProbe />} />
        <Route element={<ProtectedRoute />}>
          <Route path="/" element={<ProtectedContent />} />
        </Route>
      </Routes>,
      { initialEntries: ["/"] },
    );

    expect(await screen.findByTestId("protected-content")).toBeInTheDocument();
  });
});
