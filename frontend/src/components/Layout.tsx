import { Link, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import { Button } from "./Button";

export function Layout() {
  const auth = useAuth();
  const navigate = useNavigate();

  function handleSignOut() {
    auth.logout();
    navigate("/login");
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-2xl items-center justify-between px-4 py-4">
          <Link to="/" className="text-lg font-semibold tracking-tight">
            Notes
          </Link>
          <div className="flex items-center gap-3">
            <Link
              to="/new"
              className="rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-indigo-500"
            >
              New note
            </Link>
            {auth.status === "authenticated" && (
              <>
                <span className="text-sm text-slate-600">
                  {auth.user.email}
                </span>
                <Button variant="secondary" onClick={handleSignOut}>
                  Sign out
                </Button>
              </>
            )}
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-2xl px-4 py-8">
        <Outlet />
      </main>
    </div>
  );
}
