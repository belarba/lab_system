import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import PatientSearch from '../../../components/forms/PatientSearch'

// Mock simples do useApi
const mockRequest = vi.fn()

vi.mock('../../../hooks/useApi', () => ({
  useApi: () => ({
    request: mockRequest
  })
}))

describe('PatientSearch', () => {
  const mockOnPatientSelect = vi.fn()
  
  beforeEach(() => {
    mockRequest.mockClear()
    mockOnPatientSelect.mockClear()
    
    // Mock básico que sempre funciona
    mockRequest.mockResolvedValue({
      data: { patients: [] }
    })
  })

  it('renders search input', () => {
    render(<PatientSearch onPatientSelect={mockOnPatientSelect} />)
    
    expect(screen.getByPlaceholderText('Digite o nome ou email do paciente...')).toBeInTheDocument()
    expect(screen.getByText('Buscar Paciente *')).toBeInTheDocument()
  })

  it('shows instruction text', () => {
    render(<PatientSearch onPatientSelect={mockOnPatientSelect} />)
    
    expect(screen.getByText('Busque por nome ou email, ou selecione da lista')).toBeInTheDocument()
  })

  it('accepts text input', () => {
    render(<PatientSearch onPatientSelect={mockOnPatientSelect} />)
    
    const input = screen.getByPlaceholderText('Digite o nome ou email do paciente...')
    fireEvent.change(input, { target: { value: 'test' } })
    
    expect(input.value).toBe('test')
  })

  it('shows selected patient when provided', () => {
    const selectedPatient = { id: 1, name: 'João Silva', email: 'joao@test.com' }
    
    render(
      <PatientSearch 
        onPatientSelect={mockOnPatientSelect} 
        selectedPatient={selectedPatient}
      />
    )
    
    expect(screen.getByText('Paciente Selecionado:')).toBeInTheDocument()
    expect(screen.getByText('João Silva - joao@test.com')).toBeInTheDocument()
  })

  it('applies custom className when provided', () => {
    const { container } = render(
      <PatientSearch 
        onPatientSelect={mockOnPatientSelect} 
        className="custom-class"
      />
    )
    
    expect(container.firstChild).toHaveClass('custom-class')
  })
})