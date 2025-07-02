import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import ResultsChart from '../../../components/charts/ResultsChart'

// Mock do Recharts
vi.mock('recharts', () => ({
  LineChart: ({ children }) => <div data-testid="line-chart">{children}</div>,
  Line: () => <div data-testid="line" />,
  XAxis: () => <div data-testid="x-axis" />,
  YAxis: () => <div data-testid="y-axis" />,
  CartesianGrid: () => <div data-testid="grid" />,
  Tooltip: () => <div data-testid="tooltip" />,
  Legend: () => <div data-testid="legend" />,
  ResponsiveContainer: ({ children }) => <div data-testid="responsive-container">{children}</div>
}))

describe('ResultsChart', () => {
  const mockExamType = {
    name: 'Glucose',
    unit: 'mg/dL',
    reference_range: '70-99'
  }

  const mockData = [
    {
      performed_at: '2025-01-01T10:00:00Z',
      value: 85,
      status: 'normal'
    },
    {
      performed_at: '2025-01-02T10:00:00Z',
      value: 95,
      status: 'normal'
    },
    {
      performed_at: '2025-01-03T10:00:00Z',
      value: 110,
      status: 'high'
    }
  ]

  it('renders chart when data is provided', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={mockExamType}
        title="Test Chart"
      />
    )

    expect(screen.getByText('Test Chart')).toBeInTheDocument()
    expect(screen.getByText('Faixa de referência: 70-99')).toBeInTheDocument()
    expect(screen.getByTestId('line-chart')).toBeInTheDocument()
    expect(screen.getByTestId('responsive-container')).toBeInTheDocument()
  })

  it('shows default title when not provided', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={mockExamType}
      />
    )

    expect(screen.getByText('Tendência - Glucose')).toBeInTheDocument()
  })

  it('renders chart components', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={mockExamType}
      />
    )

    expect(screen.getByTestId('line')).toBeInTheDocument()
    expect(screen.getByTestId('x-axis')).toBeInTheDocument()
    expect(screen.getByTestId('y-axis')).toBeInTheDocument()
    expect(screen.getByTestId('grid')).toBeInTheDocument()
    expect(screen.getByTestId('tooltip')).toBeInTheDocument()
    expect(screen.getByTestId('legend')).toBeInTheDocument()
  })

  it('shows no data message when data is empty', () => {
    render(
      <ResultsChart 
        data={[]} 
        examType={mockExamType}
      />
    )

    expect(screen.getByText('Não há dados suficientes para exibir o gráfico')).toBeInTheDocument()
    expect(screen.queryByTestId('line-chart')).not.toBeInTheDocument()
  })

  it('shows no data message when data is null', () => {
    render(
      <ResultsChart 
        data={null} 
        examType={mockExamType}
      />
    )

    expect(screen.getByText('Não há dados suficientes para exibir o gráfico')).toBeInTheDocument()
  })

  it('displays reference range when provided', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={mockExamType}
      />
    )

    expect(screen.getByText('Faixa de referência: 70-99')).toBeInTheDocument()
  })

  it('does not show reference range when not provided', () => {
    const examTypeWithoutRange = {
      name: 'Test Exam',
      unit: 'units'
    }

    render(
      <ResultsChart 
        data={mockData} 
        examType={examTypeWithoutRange}
      />
    )

    expect(screen.queryByText(/Faixa de referência/)).not.toBeInTheDocument()
  })

  it('shows status legend', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={mockExamType}
      />
    )

    expect(screen.getByText('Normal')).toBeInTheDocument()
    expect(screen.getByText('Baixo')).toBeInTheDocument()
    expect(screen.getByText('Alto')).toBeInTheDocument()
  })

  it('handles data with different date formats', () => {
    const dataWithDifferentDates = [
      {
        date: '2025-01-01',
        value: 85,
        status: 'normal'
      }
    ]

    render(
      <ResultsChart 
        data={dataWithDifferentDates} 
        examType={mockExamType}
      />
    )

    expect(screen.getByTestId('line-chart')).toBeInTheDocument()
  })

  it('renders without crashing when examType is missing', () => {
    render(
      <ResultsChart 
        data={mockData} 
        examType={null}
      />
    )

    expect(screen.getByTestId('line-chart')).toBeInTheDocument()
  })
})