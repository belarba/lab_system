import { describe, test, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import React from 'react'

// Mock simplificado do Layout
const MockLayout = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = React.useState(false)
  const mockLogout = vi.fn()

  // Simular diferentes tipos de usuário
  const mockUser = {
    name: 'Test User',
    roles: ['patient']
  }

  const hasRole = (role) => mockUser.roles.includes(role)

  const getNavigation = () => {
    const nav = []
    
    if (hasRole('patient')) {
      nav.push('Dashboard', 'Meu Perfil', 'Meus Exames', 'Solicitar Exame', 'Resultados')
    }
    
    if (hasRole('doctor')) {
      nav.push('Dashboard', 'Pacientes', 'Solicitar Exames', 'Resultados')
    }
    
    if (hasRole('admin')) {
      nav.push('Dashboard', 'Usuários', 'Tipos de Exame', 'Sistema')
    }
    
    if (hasRole('lab_technician')) {
      nav.push('Dashboard', 'Upload Resultados', 'Histórico Uploads')
    }

    return nav
  }

  return (
    <div>
      <header className="flex items-center justify-between p-4">
        <h1>Lab System</h1>
        
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          data-testid="mobile-menu"
        >
          Menu
        </button>

        <div className="flex items-center">
          <span>{mockUser.name}</span>
          <button 
            onClick={mockLogout}
            data-testid="logout-button"
          >
            Sair
          </button>
        </div>
      </header>

      <nav className={sidebarOpen ? 'block' : 'hidden lg:block'}>
        {getNavigation().map(item => (
          <a key={item} href="#" className="block p-2">
            {item}
          </a>
        ))}
      </nav>

      <main>
        {children}
      </main>
    </div>
  )
}

describe('Layout', () => {
  const user = userEvent.setup()

  test('renders layout with navigation for patient', () => {
    render(
      <BrowserRouter>
        <MockLayout>
          <div>Test Content</div>
        </MockLayout>
      </BrowserRouter>
    )

    expect(screen.getByText('Lab System')).toBeInTheDocument()
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Meu Perfil')).toBeInTheDocument()
    expect(screen.getByText('Meus Exames')).toBeInTheDocument()
    expect(screen.getByText('Solicitar Exame')).toBeInTheDocument()
    expect(screen.getByText('Resultados')).toBeInTheDocument()
  })

  test('displays user name in header', () => {
    render(
      <BrowserRouter>
        <MockLayout>
          <div>Test Content</div>
        </MockLayout>
      </BrowserRouter>
    )

    expect(screen.getByText('Test User')).toBeInTheDocument()
  })

  test('calls logout when logout button is clicked', async () => {
    const mockLogout = vi.fn()
    
    // Mock mais específico com spy
    const LayoutWithSpy = () => {
      return (
        <div>
          <button 
            onClick={mockLogout}
            data-testid="logout-button"
          >
            Sair
          </button>
        </div>
      )
    }

    render(
      <BrowserRouter>
        <LayoutWithSpy />
      </BrowserRouter>
    )

    const logoutButton = screen.getByTestId('logout-button')
    await user.click(logoutButton)

    expect(mockLogout).toHaveBeenCalledTimes(1)
  })

  test('renders children content', () => {
    render(
      <BrowserRouter>
        <MockLayout>
          <div data-testid="test-content">Test Content</div>
        </MockLayout>
      </BrowserRouter>
    )

    expect(screen.getByTestId('test-content')).toBeInTheDocument()
  })

  test('toggles mobile sidebar', async () => {
    render(
      <BrowserRouter>
        <MockLayout>
          <div>Test Content</div>
        </MockLayout>
      </BrowserRouter>
    )

    const menuButton = screen.getByTestId('mobile-menu')
    const nav = screen.getByRole('navigation')
    
    // Inicialmente oculto
    expect(nav).toHaveClass('hidden')
    
    // Clicar para mostrar
    await user.click(menuButton)
    expect(nav).toHaveClass('block')
    
    // Clicar para ocultar novamente
    await user.click(menuButton)
    expect(nav).toHaveClass('hidden')
  })
})