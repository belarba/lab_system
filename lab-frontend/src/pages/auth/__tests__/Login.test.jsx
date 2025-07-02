import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import Login from '../Login'

// Mock simples e direto
const mockLogin = vi.fn()

vi.mock('../../../hooks/useAuth', () => ({
  useAuth: () => ({
    login: mockLogin,
    isAuthenticated: false,
    loading: false,
    error: null
  })
}))

// Wrapper simples
const TestWrapper = ({ children }) => (
  <BrowserRouter>
    {children}
  </BrowserRouter>
)

describe('Login', () => {
  beforeEach(() => {
    mockLogin.mockClear()
    mockLogin.mockResolvedValue({ success: true })
  })

  it('renders basic elements', () => {
    render(
      <TestWrapper>
        <Login />
      </TestWrapper>
    )

    expect(screen.getByText('Lab System')).toBeInTheDocument()
    expect(screen.getByText('Entre na sua conta')).toBeInTheDocument()
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Senha')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Entrar' })).toBeInTheDocument()
  })

  it('shows example credentials', () => {
    render(
      <TestWrapper>
        <Login />
      </TestWrapper>
    )

    expect(screen.getByText('Admin')).toBeInTheDocument()
    expect(screen.getByText('Médico')).toBeInTheDocument()
    expect(screen.getByText('Paciente')).toBeInTheDocument()
    expect(screen.getByText('Lab Tech')).toBeInTheDocument()
  })

  it('fills form when clicking example credentials', async () => {
    render(
      <TestWrapper>
        <Login />
      </TestWrapper>
    )

    const emailField = screen.getByLabelText('Email')
    const passwordField = screen.getByLabelText('Senha')
    const adminButton = screen.getByText('Admin').closest('button')

    fireEvent.click(adminButton)

    expect(emailField.value).toBe('admin@labsystem.pt')
    expect(passwordField.value).toBe('admin123')
  })

  it('submits form with correct data', async () => {
    render(
      <TestWrapper>
        <Login />
      </TestWrapper>
    )

    const emailField = screen.getByLabelText('Email')
    const passwordField = screen.getByLabelText('Senha')
    const submitButton = screen.getByRole('button', { name: 'Entrar' })

    fireEvent.change(emailField, { target: { value: 'test@example.com' } })
    fireEvent.change(passwordField, { target: { value: 'password123' } })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'password123')
    })
  })

  it('form fields have correct attributes', () => {
    render(
      <TestWrapper>
        <Login />
      </TestWrapper>
    )

    const emailField = screen.getByLabelText('Email')
    const passwordField = screen.getByLabelText('Senha')

    expect(emailField).toHaveAttribute('type', 'email')
    expect(emailField).toHaveAttribute('required')
    expect(passwordField).toHaveAttribute('type', 'password')
    expect(passwordField).toHaveAttribute('required')
  })
})