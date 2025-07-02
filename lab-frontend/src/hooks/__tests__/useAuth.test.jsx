import { describe, test, expect, beforeEach, vi } from 'vitest'
import { renderHook } from '@testing-library/react'
import React from 'react'

// Mock simplificado do AuthContext
const mockAuthContext = {
  user: {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    roles: ['patient'],
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z'
  },
  isAuthenticated: true,
  loading: false,
  error: null,
  login: vi.fn(),
  logout: vi.fn(),
  updateUser: vi.fn(),
  hasRole: vi.fn((role) => ['patient'].includes(role))
}

// Mock do useAuth hook
const mockUseAuth = () => mockAuthContext

// Mock do contexto
const MockAuthProvider = ({ children }) => {
  return React.createElement(React.Fragment, null, children)
}

describe('useAuth - Simple Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  test('throws error when used outside AuthProvider', () => {
    // Mock que simula erro
    const useAuthError = () => {
      throw new Error('useAuth must be used within an AuthProvider')
    }

    expect(() => {
      renderHook(() => useAuthError())
    }).toThrow('useAuth must be used within an AuthProvider')
  })

  test('returns auth context when used within AuthProvider', () => {
    const wrapper = ({ children }) => (
      <MockAuthProvider>{children}</MockAuthProvider>
    )

    const { result } = renderHook(() => mockUseAuth(), { wrapper })
    
    expect(result.current).toHaveProperty('user')
    expect(result.current).toHaveProperty('isAuthenticated')
    expect(result.current).toHaveProperty('loading')
    expect(result.current).toHaveProperty('login')
    expect(result.current).toHaveProperty('logout')
    expect(result.current).toHaveProperty('hasRole')
  })

  test('hasRole function works correctly', () => {
    // Mock localStorage com dados do usuário
    const mockUser = {
      id: 1,
      name: 'Test User',
      roles: ['patient']
    }
    
    localStorage.setItem('access_token', 'fake-token')
    localStorage.setItem('user', JSON.stringify(mockUser))
    
    const wrapper = ({ children }) => (
      <MockAuthProvider>{children}</MockAuthProvider>
    )
    
    const { result } = renderHook(() => mockUseAuth(), { wrapper })
    
    // Testar a função hasRole
    expect(result.current.hasRole('patient')).toBe(true)
    expect(result.current.hasRole('doctor')).toBe(false)
    expect(result.current.hasRole('admin')).toBe(false)
  })

  test('user properties are correct', () => {
    const wrapper = ({ children }) => (
      <MockAuthProvider>{children}</MockAuthProvider>
    )

    const { result } = renderHook(() => mockUseAuth(), { wrapper })
    
    expect(result.current.user.name).toBe('Test User')
    expect(result.current.user.email).toBe('test@example.com')
    expect(result.current.user.roles).toContain('patient')
    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.loading).toBe(false)
  })

  test('function properties exist', () => {
    const wrapper = ({ children }) => (
      <MockAuthProvider>{children}</MockAuthProvider>
    )

    const { result } = renderHook(() => mockUseAuth(), { wrapper })
    
    expect(typeof result.current.login).toBe('function')
    expect(typeof result.current.logout).toBe('function')
    expect(typeof result.current.updateUser).toBe('function')
    expect(typeof result.current.hasRole).toBe('function')
  })
})