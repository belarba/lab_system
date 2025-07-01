import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import ResultsChart from '../../components/charts/ResultsChart';
import {
  ChartBarIcon,
  DocumentTextIcon,
  FunnelIcon,
  XMarkIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';

const PatientResults = () => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [results, setResults] = useState([]);
  const [filteredResults, setFilteredResults] = useState([]);
  const [trends, setTrends] = useState([]);
  const [summary, setSummary] = useState(null);
  const [examTypes, setExamTypes] = useState([]);
  const [loadingData, setLoadingData] = useState(true);
  const [selectedExamType, setSelectedExamType] = useState('');
  
  // Estados de filtro
  const [filters, setFilters] = useState({
    examType: '',
    status: '',
    dateFrom: '',
    dateTo: ''
  });

  const fetchData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar resultados do paciente
      const response = await request({
        method: 'GET',
        url: `/patients/${user.id}/test_results`
      });
      
      if (response.data) {
        setResults(response.data.test_results || []);
        setFilteredResults(response.data.test_results || []);
        setTrends(response.data.trends || []);
        setSummary(response.data.summary || null);
      }

      // Buscar tipos de exame para filtros
      const typesResponse = await request({
        method: 'GET',
        url: '/exam_types'
      });
      
      if (typesResponse.data) {
        setExamTypes(typesResponse.data.exam_types || []);
      }
      
    } catch (error) {
      console.error('Erro ao buscar resultados:', error);
    } finally {
      setLoadingData(false);
    }
  }, [request, user.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Aplicar filtros
  useEffect(() => {
    let filtered = [...results];

    if (filters.examType) {
      filtered = filtered.filter(result => 
        result.exam_type.id.toString() === filters.examType
      );
    }

    if (filters.status) {
      filtered = filtered.filter(result => result.status === filters.status);
    }

    if (filters.dateFrom) {
      filtered = filtered.filter(result => 
        new Date(result.performed_at) >= new Date(filters.dateFrom)
      );
    }

    if (filters.dateTo) {
      filtered = filtered.filter(result => 
        new Date(result.performed_at) <= new Date(filters.dateTo)
      );
    }

    setFilteredResults(filtered);
  }, [filters, results]);

  const handleFilterChange = (field, value) => {
    setFilters(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const clearFilters = () => {
    setFilters({
      examType: '',
      status: '',
      dateFrom: '',
      dateTo: ''
    });
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'normal':
        return <CheckCircleIcon className="h-5 w-5 text-green-500" />;
      case 'high':
        return <ArrowTrendingUpIcon className="h-5 w-5 text-red-500" />;
      case 'low':
        return <ArrowTrendingDownIcon className="h-5 w-5 text-orange-500" />;
      default:
        return <DocumentTextIcon className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alto';
      case 'low':
        return 'Baixo';
      default:
        return 'N/A';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'normal':
        return 'bg-green-100 text-green-800';
      case 'high':
        return 'bg-red-100 text-red-800';
      case 'low':
        return 'bg-orange-100 text-orange-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  // Função auxiliar para formatar números
  const formatNumber = (value, decimals = 1) => {
    const num = parseFloat(value);
    return isNaN(num) ? '0' : num.toFixed(decimals);
  };

  // Função auxiliar para formatar datas
  const formatDate = (dateString) => {
    try {
      return new Date(dateString).toLocaleDateString('pt-BR');
    } catch {
      return 'Data inválida';
    }
  };

  // Preparar dados para gráfico do tipo selecionado
  const getChartData = (examTypeId) => {
    return results
      .filter(result => result.exam_type.id.toString() === examTypeId.toString())
      .sort((a, b) => new Date(a.performed_at) - new Date(b.performed_at))
      .map(result => ({
        date: result.performed_at,
        value: parseFloat(result.value),
        status: result.status,
        performed_at: result.performed_at
      }));
  };

  if (loadingData) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Meus Resultados</h1>
        <p className="text-gray-600">Visualize e acompanhe seus resultados laboratoriais</p>
      </div>

      {/* Resumo Estatístico */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="card">
            <div className="flex items-center">
              <DocumentTextIcon className="h-8 w-8 text-gray-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Total de Resultados</p>
                <p className="text-2xl font-bold text-gray-900">{summary.total_results || 0}</p>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <CheckCircleIcon className="h-8 w-8 text-green-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Normais</p>
                <p className="text-2xl font-bold text-green-900">{summary.normal_count || 0}</p>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <ArrowTrendingUpIcon className="h-8 w-8 text-red-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Altos</p>
                <p className="text-2xl font-bold text-red-900">{summary.high_count || 0}</p>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <ArrowTrendingDownIcon className="h-8 w-8 text-orange-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Baixos</p>
                <p className="text-2xl font-bold text-orange-900">{summary.low_count || 0}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Seleção de Gráfico por Tipo de Exame */}
      {trends.length > 0 && (
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center">
              <ChartBarIcon className="h-6 w-6 text-primary-600 mr-2" />
              <h2 className="text-xl font-semibold text-gray-900">Tendências por Tipo de Exame</h2>
            </div>
            <select
              value={selectedExamType}
              onChange={(e) => setSelectedExamType(e.target.value)}
              className="input-field w-64"
            >
              <option value="">Selecione um tipo de exame</option>
              {trends.map(trend => (
                <option key={trend.exam_type.id} value={trend.exam_type.id}>
                  {trend.exam_type.name} ({trend.results_count || 0} resultados)
                </option>
              ))}
            </select>
          </div>

          {selectedExamType ? (
            (() => {
              const selectedTrend = trends.find(t => t.exam_type.id.toString() === selectedExamType);
              const chartData = getChartData(selectedExamType);
              
              if (!selectedTrend) {
                return (
                  <div className="text-center py-8 bg-gray-50 rounded-lg">
                    <p className="text-sm text-gray-500">Dados do exame não encontrados</p>
                  </div>
                );
              }
              
              return (
                <div className="space-y-4">
                  {/* Informações do exame selecionado */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <div className="bg-blue-50 p-4 rounded-lg">
                      <p className="text-sm font-medium text-blue-900">Último Valor</p>
                      <p className="text-lg font-bold text-blue-900">
                        {selectedTrend.latest_value || 'N/A'} {selectedTrend.exam_type.unit || ''}
                      </p>
                      <p className="text-xs text-blue-600">
                        {selectedTrend.latest_date ? formatDate(selectedTrend.latest_date) : 'N/A'}
                      </p>
                    </div>
                    <div className="bg-green-50 p-4 rounded-lg">
                      <p className="text-sm font-medium text-green-900">Média</p>
                      <p className="text-lg font-bold text-green-900">
                        {formatNumber(selectedTrend.average_value)} {selectedTrend.exam_type.unit || ''}
                      </p>
                    </div>
                    <div className="bg-gray-50 p-4 rounded-lg">
                      <p className="text-sm font-medium text-gray-900">Total de Resultados</p>
                      <p className="text-lg font-bold text-gray-900">{selectedTrend.results_count || 0}</p>
                    </div>
                  </div>

                  {/* Gráfico */}
                  {chartData.length > 0 ? (
                    <ResultsChart 
                      data={chartData}
                      examType={selectedTrend.exam_type}
                      title={`Tendência - ${selectedTrend.exam_type.name}`}
                    />
                  ) : (
                    <div className="text-center py-8 bg-gray-50 rounded-lg">
                      <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
                      <h3 className="mt-2 text-sm font-medium text-gray-900">Dados insuficientes</h3>
                      <p className="mt-1 text-sm text-gray-500">
                        Não há dados suficientes para gerar o gráfico de tendência
                      </p>
                    </div>
                  )}
                </div>
              );
            })()
          ) : (
            <div className="text-center py-12 bg-gray-50 rounded-lg">
              <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Selecione um tipo de exame</h3>
              <p className="mt-1 text-sm text-gray-500">
                Escolha um tipo de exame acima para visualizar a tendência ao longo do tempo
              </p>
            </div>
          )}
        </div>
      )}

      {/* Filtros */}
      <div className="card">
        <div className="flex items-center mb-4">
          <FunnelIcon className="h-5 w-5 text-gray-400 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Filtros</h3>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tipo de Exame
            </label>
            <select
              value={filters.examType}
              onChange={(e) => handleFilterChange('examType', e.target.value)}
              className="input-field"
            >
              <option value="">Todos os tipos</option>
              {examTypes.map(type => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Status do Resultado
            </label>
            <select
              value={filters.status}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="input-field"
            >
              <option value="">Todos os status</option>
              <option value="normal">Normal</option>
              <option value="high">Alto</option>
              <option value="low">Baixo</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data Início
            </label>
            <input
              type="date"
              value={filters.dateFrom}
              onChange={(e) => handleFilterChange('dateFrom', e.target.value)}
              className="input-field"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data Fim
            </label>
            <input
              type="date"
              value={filters.dateTo}
              onChange={(e) => handleFilterChange('dateTo', e.target.value)}
              className="input-field"
            />
          </div>
        </div>

        {(filters.examType || filters.status || filters.dateFrom || filters.dateTo) && (
          <div className="mt-4 flex justify-between items-center">
            <p className="text-sm text-gray-600">
              Mostrando {filteredResults.length} de {results.length} resultados
            </p>
            <button
              onClick={clearFilters}
              className="btn-secondary text-sm"
            >
              <XMarkIcon className="h-4 w-4 mr-1" />
              Limpar Filtros
            </button>
          </div>
        )}
      </div>

      {/* Lista de Resultados */}
      {filteredResults.length > 0 ? (
        <div className="card">
          <div className="overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Exame
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Valor
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Referência
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Data Realização
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Técnico
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredResults.map((result) => (
                  <tr key={result.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <DocumentTextIcon className="h-5 w-5 text-gray-400 mr-3" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {result.exam_type.name}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {result.value} {result.unit}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">
                        {result.exam_type.reference_range || 'N/A'}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {getStatusIcon(result.status)}
                        <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(result.status)}`}>
                          {getStatusText(result.status)}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatDate(result.performed_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {result.lab_technician.name}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="card text-center py-12">
          <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            {results.length === 0 ? 'Nenhum resultado encontrado' : 'Nenhum resultado corresponde aos filtros'}
          </h3>
          <p className="mt-1 text-sm text-gray-500">
            {results.length === 0 
              ? 'Você ainda não possui resultados de exames.'
              : 'Tente ajustar os filtros para ver mais resultados.'
            }
          </p>
          {results.length === 0 && (
            <div className="mt-6">
              <a href="/patient/request" className="btn-primary">
                Solicitar Primeiro Exame
              </a>
            </div>
          )}
        </div>
      )}

      {/* Interpretação de Resultados */}
      <div className="card bg-blue-50 border-blue-200">
        <div className="flex items-center mb-4">
          <ExclamationTriangleIcon className="h-6 w-6 text-blue-600 mr-2" />
          <h3 className="text-lg font-medium text-blue-900">Interpretação de Resultados</h3>
        </div>
        <div className="text-sm text-blue-700 space-y-2">
          <p><strong>Normal:</strong> Valores dentro da faixa de referência estabelecida</p>
          <p><strong>Alto:</strong> Valores acima da faixa de referência - pode necessitar atenção médica</p>
          <p><strong>Baixo:</strong> Valores abaixo da faixa de referência - pode necessitar atenção médica</p>
          <p className="mt-4 font-medium">
            ⚠️ <strong>Importante:</strong> Resultados alterados não significam necessariamente doença. 
            Sempre consulte seu médico para interpretação adequada dos resultados.
          </p>
        </div>
      </div>
    </div>
  );
};

export default PatientResults;