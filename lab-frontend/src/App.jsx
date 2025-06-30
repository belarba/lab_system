import React from 'react';
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { useAuth } from './hooks/useAuth';
import Layout from './components/layout/Layout';
import Login from './pages/auth/Login';
import PatientDashboard from './pages/patient/Dashboard';
import DoctorDashboard from './pages/doctor/Dashboard';
import LabDashboard from './pages/lab/Dashboard';
import AdminDashboard from './pages/admin/Dashboard';
import LoadingSpinner from './components/common/LoadingSpinner';

// Componente para rotas protegidas
const ProtectedRoute = ({ children, requiredRole }) => {
  const { isAuthenticated, hasRole, loading } = useAuth();
  
  if (loading) {
    return <LoadingSpinner />;
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (requiredRole && !hasRole(requiredRole)) {
    return <Navigate to="/unauthorized" replace />;
  }
  
  return children;
};

// Componente para redirecionamento baseado em role
const RoleBasedRedirect = () => {
  const { hasRole } = useAuth();
  
  if (hasRole('admin')) {
    return <Navigate to="/admin" replace />;
  } else if (hasRole('doctor')) {
    return <Navigate to="/doctor" replace />;
  } else if (hasRole('lab_technician')) {
    return <Navigate to="/lab" replace />;
  } else if (hasRole('patient')) {
    return <Navigate to="/patient" replace />;
  }
  
  return <Navigate to="/login" replace />;
};

const router = createBrowserRouter([
  {
    path: "/login",
    element: <Login />
  },
  {
    path: "/unauthorized",
    element: (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">Acesso Negado</h1>
          <p className="text-gray-600">Você não tem permissão para acessar esta página.</p>
        </div>
      </div>
    )
  },
  {
    path: "/",
    element: (
      <ProtectedRoute>
        <Layout>
          <RoleBasedRedirect />
        </Layout>
      </ProtectedRoute>
    )
  },
  {
    path: "/patient/*",
    element: (
      <ProtectedRoute requiredRole="patient">
        <Layout>
          <PatientDashboard />
        </Layout>
      </ProtectedRoute>
    )
  },
  {
    path: "/doctor/*",
    element: (
      <ProtectedRoute requiredRole="doctor">
        <Layout>
          <DoctorDashboard />
        </Layout>
      </ProtectedRoute>
    )
  },
  {
    path: "/lab/*",
    element: (
      <ProtectedRoute requiredRole="lab_technician">
        <Layout>
          <LabDashboard />
        </Layout>
      </ProtectedRoute>
    )
  },
  {
    path: "/admin/*",
    element: (
      <ProtectedRoute requiredRole="admin">
        <Layout>
          <AdminDashboard />
        </Layout>
      </ProtectedRoute>
    )
  }
]);

function App() {
  return (
    <AuthProvider>
      <div className="App">
        <RouterProvider router={router} />
      </div>
    </AuthProvider>
  );
}

export default App;