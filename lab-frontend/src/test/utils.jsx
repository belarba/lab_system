import React from 'react'
import { render } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { vi } from 'vitest'
import { AuthProvider } from '../contexts/AuthContext'

// Mock user para testes
export const mockUser = {
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  phone: '+351 91 234 5678',
  roles: ['patient'],
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z'
}

// Diferentes tipos de usuários para testes
export const mockUsers = {
  patient: {
    ...mockUser,
    roles: ['patient']
  },
  doctor: {
    ...mockUser,
    id: 2,
    name: 'Dr. Test',
    email: 'doctor@example.com',
    roles: ['doctor']
  },
  admin: {
    ...mockUser,
    id: 3,
    name: 'Admin Test',
    email: 'admin@example.com',
    roles: ['admin']
  },
  labTech: {
    ...mockUser,
    id: 4,
    name: 'Lab Tech Test',
    email: 'lab@example.com',
    roles: ['lab_technician']
  }
}

// Mock do contexto de autenticação
export const mockAuthContext = {
  user: mockUser,
  isAuthenticated: true,
  loading: false,
  error: null,
  login: vi.fn(),
  logout: vi.fn(),
  updateUser: vi.fn(),
  hasRole: vi.fn((role) => mockUser.roles.includes(role))
}

// Criar contexto para diferentes tipos de usuário
export const createMockAuthContext = (userType = 'patient') => {
  const user = mockUsers[userType]
  return {
    user,
    isAuthenticated: true,
    loading: false,
    error: null,
    login: vi.fn(),
    logout: vi.fn(),
    updateUser: vi.fn(),
    hasRole: vi.fn((role) => user.roles.includes(role))
  }
}

// Provider de teste customizado
export const TestWrapper = ({ children, authValue = mockAuthContext }) => {
  return (
    <BrowserRouter>
      <AuthProvider value={authValue}>
        {children}
      </AuthProvider>
    </BrowserRouter>
  )
}

// Função de render customizada
export const renderWithProviders = (ui, options = {}) => {
  const { authValue, ...renderOptions } = options
  
  const Wrapper = ({ children }) => (
    <TestWrapper authValue={authValue}>
      {children}
    </TestWrapper>
  )
  
  return render(ui, { wrapper: Wrapper, ...renderOptions })
}

// Render para diferentes tipos de usuário
export const renderAsPatient = (ui, options = {}) => {
  return renderWithProviders(ui, {
    ...options,
    authValue: createMockAuthContext('patient')
  })
}

export const renderAsDoctor = (ui, options = {}) => {
  return renderWithProviders(ui, {
    ...options,
    authValue: createMockAuthContext('doctor')
  })
}

export const renderAsAdmin = (ui, options = {}) => {
  return renderWithProviders(ui, {
    ...options,
    authValue: createMockAuthContext('admin')
  })
}

// Mock da API
export const mockApiResponse = (data, error = null) => ({
  data,
  error,
  loading: false
})

// Mock de requisições HTTP
export const mockFetch = (response, ok = true) => {
  if (!window.fetch || !window.fetch.mockResolvedValueOnce) {
    console.warn('window.fetch não está mockado. Certifique-se de que setup.js está sendo executado.')
    return
  }
  
  window.fetch.mockResolvedValueOnce({
    ok,
    json: async () => response,
    status: ok ? 200 : 400,
    text: async () => JSON.stringify(response),
    headers: new Headers({
      'content-type': 'application/json',
    }),
  })
}

// Mock de erro de API
export const mockFetchError = (error = 'Network Error') => {
  if (!window.fetch || !window.fetch.mockRejectedValueOnce) {
    console.warn('window.fetch não está mockado. Certifique-se de que setup.js está sendo executado.')
    return
  }
  
  window.fetch.mockRejectedValueOnce(new Error(error))
}

// Dados mock comuns para testes
export const mockExamTypes = [
  {
    id: 1,
    name: 'Glucose',
    description: 'Blood glucose test',
    unit: 'mg/dL',
    reference_range: '70-99'
  },
  {
    id: 2,
    name: 'Cholesterol',
    description: 'Total cholesterol test',
    unit: 'mg/dL',
    reference_range: '< 200'
  }
]

export const mockExamRequests = [
  {
    id: 1,
    patient: mockUsers.patient,
    doctor: mockUsers.doctor,
    exam_type: mockExamTypes[0],
    status: 'scheduled',
    scheduled_date: '2024-02-01',
    created_at: '2024-01-15T10:00:00Z'
  }
]

export const mockExamResults = [
  {
    id: 1,
    exam_type: mockExamTypes[0],
    value: '95.5',
    unit: 'mg/dL',
    status: 'normal',
    performed_at: '2024-01-15T09:30:00Z',
    lab_technician: mockUsers.labTech
  }
]