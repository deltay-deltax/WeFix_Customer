import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard.tsx';

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={
        <RequireAuth>
          <Dashboard />
        </RequireAuth>
      } />
    </Routes>
  );
}

function RequireAuth({ children }: { children: React.ReactNode }) {
  const isAdminLoggedIn = localStorage.getItem('wefix_admin_auth') === 'true';
  return isAdminLoggedIn ? children : <Navigate to="/login" replace />;
}

export default App;
