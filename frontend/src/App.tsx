import { Routes, Route } from "react-router-dom";
import { Layout } from "./components/Layout";
import { NotesListPage } from "./pages/NotesListPage";
import { NoteCreatePage } from "./pages/NoteCreatePage";
import { NoteEditPage } from "./pages/NoteEditPage";
import { LoginPage } from "./pages/LoginPage";
import { RegisterPage } from "./pages/RegisterPage";
import { ProtectedRoute } from "./auth/ProtectedRoute";

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<Layout />}>
          <Route index element={<NotesListPage />} />
          <Route path="new" element={<NoteCreatePage />} />
          <Route path=":id/edit" element={<NoteEditPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
