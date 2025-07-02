import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import RequestExamForm from '../../../components/forms/RequestExamForm'

// Mocks simples
const mockRequest = vi.fn()
const mockHasRole = vi.fn()
const mockUser = { id: 1, name: 'Test User', email: 'test@test.com' }

vi.mock('../../../hooks/useApi', () => ({
  useApi: () => ({
    request: mockRequest,
    loading: false
  })
}))

vi.mock('../../../hooks/useAuth', () => ({
  useAuth: () => ({
    user: mockUser,
    hasRole: mockHasRole
  })
}))

describe('RequestExamForm', () => {
  const mockOnSuccess = vi.fn()
  const mockOnCancel = vi.fn()

  beforeEach(() => {
    mockRequest.mockClear()
    mockOnSuccess.mockClear()
    mockOnCancel.mockClear()
    mockHasRole.mockReturnValue(false)

    // Mock simples para tipos de exame
    mockRequest.mockResolvedValue({
      data: {
        exam_types: [
          { id: 1, name: 'Glucose', description: 'Teste de glicose', unit: 'mg/dL' }
        ]
      }
    })
  })

  it('renders form title', async () => {
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      expect(screen.getByText('Solicitar Exame Laboratorial')).toBeInTheDocument()
    })
  })

  it('renders basic form fields', async () => {
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      expect(screen.getByText('Tipo de Exame *')).toBeInTheDocument()
      expect(screen.getByText('Data Preferida *')).toBeInTheDocument()
      expect(screen.getByText('Observações')).toBeInTheDocument()
    })
  })

  it('shows patient info for patient role', async () => {
    mockHasRole.mockImplementation(role => role === 'patient')
    
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      expect(screen.getByText('Solicitando para:')).toBeInTheDocument()
      expect(screen.getByText('Test User')).toBeInTheDocument()
    })
  })

  it('shows patient search for doctor role', async () => {
    mockHasRole.mockImplementation(role => role === 'doctor')
    
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      expect(screen.getByText('Buscar Paciente *')).toBeInTheDocument()
    })
  })

  it('calls onCancel when cancel button is clicked', async () => {
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      const cancelButton = screen.getByText('Cancelar')
      fireEvent.click(cancelButton)
    })
    
    expect(mockOnCancel).toHaveBeenCalled()
  })

  it('shows submit button', async () => {
    render(<RequestExamForm onSuccess={mockOnSuccess} onCancel={mockOnCancel} />)
    
    await waitFor(() => {
      expect(screen.getByText('Solicitar Exame')).toBeInTheDocument()
    })
  })
})