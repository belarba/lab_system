import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import ResultsChart from '../../components/charts/ResultsChart';
import {
  ChartBarIcon,
  DocumentArrowDownIcon,
  FunnelIcon,
  XMarkIcon,
  UserIcon,
  BeakerIcon,
  CalendarIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon
} from '@heroicons/react/24/outline';

const DoctorResults = () => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [results, setResults] = useState([]);
  const [filteredResults, setFilteredResults] = useState([]);
  const [patients, setPatients] = useState([]);
  const [examTypes, setExamTypes] = useState([]);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [patientTrends, setPatientTrends] = useState([]);
  const [loadingData, setLoadingData] = useState(true);
  const [loadingTrends, setLoadingTrends] = useState(false);
  const [exportingCSV, setExportingCSV] = useState(false);
  
  // Estados de filtro
  const [filters, setFilters] = useState({
    patient: '',
    examType: '',
    status: '',
    dateFrom: '',
    dateTo: ''
  });

  // Estados de paginação
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  const fetchData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar pacientes do médico
      const patientsResponse = await request({
        method: 'GET',
        url: `/doctors/${user.id}/patients`
      });
      
      if (patientsResponse.data) {
        setPatients(patientsResponse.data.patients || []);
      }

      // Buscar tipos de exame
      const typesResponse = await request({
        method: 'GET',
        url: '/exam_types'
      });
      
      if (typesResponse.data) {
        setExamTypes(typesResponse.data.exam_types || []);
      }

      // Buscar todos os resultados das solicitações do médico
      const requestsResponse = await request({
        method: 'GET',
        url: `/doctors/${user.id}/blood_work_requests`
      });
      
      if (requestsResponse.data) {
        const allRequests = requestsResponse.data.blood_work_requests || [];
        // Filtrar apenas os que têm resultados
        const resultsData = allRequests
          .filter(req => req.result)
          .map(req => ({
            ...req.result,
            patient: req.patient,
            exam_type: req.exam_type,
            exam_request: req,
            doctor: req.doctor
          }));
        setResults(resultsData);
        setFilteredResults(resultsData);
      }
      
    } catch (error) {
      console.error('Erro ao buscar dados:', error);
    } finally {
      setLoadingData(false);
    }
  }, [request, user.id]);

  const fetchPatientTrends = async (patientId) => {
    try {
      setLoadingTrends(true);
      
      const response = await request({
        method: 'GET',
        url: `/patients/${patientId}/test_results`
      });
      
      if (response.data) {
        setPatientTrends(response.data.trends || []);
      }
      
    } catch (error) {
      console.error('Erro ao buscar tendências do paciente:', error);
    } finally {
      setLoadingTrends(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Aplicar filtros
  useEffect(() => {
    let filtered = [...results];

    if (filters.patient) {
      filtered = filtered.filter(result => result.patient.id.toString() === filters.patient);
    }

    if (filters.examType) {
      filtered = filtered.filter(result => result.exam_type.id.toString() === filters.examType);
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

    // Ordenar por data de realização (mais recentes primeiro)
    filtered.sort((a, b) => new Date(b.performed_at) - new Date(a.performed_at));

    setFilteredResults(filtered);
    setCurrentPage(1); // Reset para primeira página ao filtrar
  }, [filters, results]);

  const handleFilterChange = (field, value) => {
    setFilters(prev => ({
      ...prev,
      [field]: value
    }));

    // Se mudou o paciente, buscar tendências
    if (field === 'patient' && value) {
      setSelectedPatient(patients.find(p => p.id.toString() === value));
      fetchPatientTrends(value);
    } else if (field === 'patient' && !value) {
      setSelectedPatient(null);
      setPatientTrends([]);
    }
  };

  const clearFilters = () => {
    setFilters({
      patient: '',
      examType: '',
      status: '',
      dateFrom: '',
      dateTo: ''
    });
    setSelectedPatient(null);
    setPatientTrends([]);
  };

  const exportToCSV = async (type = 'filtered') => {
    try {
      setExportingCSV(true);

      let url;
      const params = new URLSearchParams();

      if (type === 'patient' && selectedPatient) {
        url = `/doctors/${user.id}/export/patient/${selectedPatient.id}`;
      } else {
        url = `/doctors/${user.id}/export/all`;
      }

      // Adicionar filtros como parâmetros
      if (filters.examType) params.append('exam_type_id', filters.examType);
      if (filters.dateFrom) params.append('from_date', filters.dateFrom);
      if (filters.dateTo) params.append('to_date', filters.dateTo);

      const queryString = params.toString();
      const fullUrl = queryString ? `${url}?${queryString}` : url;

      const response = await request({
        method: 'GET',
        url: fullUrl
      });

      if (response.data && response.data.csv_data) {
        // Criar e baixar arquivo CSV
        const blob = new Blob([response.data.csv_data], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url_blob = URL.createObjectURL(blob);
        
        link.setAttribute('href', url_blob);
        link.setAttribute('download', 
          type === 'patient' && selectedPatient 
            ? `resultados_${selectedPatient.name.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.csv`
            : `todos_resultados_${new Date().toISOString().split('T')[0]}.csv`
        );
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        alert(`CSV exportado com sucesso! ${response.data.results_count} resultados incluídos.`);
      } else {
        alert('Erro ao exportar CSV: ' + (response.error || 'Dados não encontrados'));
      }
    } catch (error) {
      console.error('Erro ao exportar CSV:', error);
      alert('Erro ao exportar CSV');
    } finally {
      setExportingCSV(false);
    }
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
      case 'normal': return 'Normal';
      case 'high': return 'Alto';
      case 'low': return 'Baixo';
      default: return 'N/A';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'normal': return 'bg-green-100 text-green-800';
      case 'high': return 'bg-red-100 text-red-800';
      case 'low': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  // Paginação
  const totalPages = Math.ceil(filteredResults.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentResults = filteredResults.slice(startIndex, endIndex);

  // Estatísticas dos resultados filtrados
  const stats = {
    total: filteredResults.length,
    normal: filteredResults.filter(r => r.status === 'normal').length,
    high: filteredResults.filter(r => r.status === 'high').length,
    low: filteredResults.filter(r => r.status === 'low').length
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
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Resultados dos Pacientes</h1>
          <p className="text-gray-600">Analise resultados e tendências dos seus pacientes</p>
        </div>
        <div className="flex space-x-3">
          {selectedPatient && (
            <button
              onClick={() => exportToCSV('patient')}
              disabled={exportingCSV}
              className="btn-secondary flex items-center"
            >
              {exportingCSV ? (
                <LoadingSpinner size="sm" className="mr-2" />
              ) : (
                <DocumentArrowDownIcon className="h-5 w-5 mr-2" />
              )}
              Exportar Paciente
            </button>
          )}
          <button
            onClick={() => exportToCSV('all')}
            disabled={exportingCSV}
            className="btn-primary flex items-center"
          >
            {exportingCSV ? (
              <LoadingSpinner size="sm" className="mr-2" />
            ) : (
              <DocumentArrowDownIcon className="h-5 w-5 mr-2" />
            )}
            Exportar Todos
          </button>
        </div>
      </div>

      {/* Estatísticas Rápidas */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center">
            <DocumentTextIcon className="h-8 w-8 text-gray-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Total</p>
              <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <CheckCircleIcon className="h-8 w-8 text-green-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Normais</p>
              <p className="text-2xl font-bold text-green-900">{stats.normal}</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <ArrowTrendingUpIcon className="h-8 w-8 text-red-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Altos</p>
              <p className="text-2xl font-bold text-red-900">{stats.high}</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <ArrowTrendingDownIcon className="h-8 w-8 text-orange-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Baixos</p>
              <p className="text-2xl font-bold text-orange-900">{stats.low}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filtros */}
      <div className="card">
        <div className="flex items-center mb-4">
          <FunnelIcon className="h-5 w-5 text-gray-400 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Filtros</h3>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Paciente
            </label>
            <select
              value={filters.patient}
              onChange={(e) => handleFilterChange('patient', e.target.value)}
              className="input-field"
            >
              <option value="">Todos os pacientes</option>
              {patients.map(patient => (
                <option key={patient.id} value={patient.id}>
                  {patient.name}
                </option>
              ))}
            </select>
          </div>

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

        {(filters.patient || filters.examType || filters.status || filters.dateFrom || filters.dateTo) && (
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

      {/* Gráfico de Tendências do Paciente Selecionado */}
      {selectedPatient && (
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center">
              <ChartBarIcon className="h-6 w-6 text-primary-600 mr-2" />
              <h2 className="text-xl font-semibold text-gray-900">
                Tendências - {selectedPatient.name}
              </h2>
            </div>
          </div>

          {loadingTrends ? (
            <div className="flex justify-center py-8">
              <LoadingSpinner size="lg" />
            </div>
          ) : patientTrends.length > 0 ? (
            <div className="space-y-6">
              {patientTrends.map(trend => {
                const chartData = trend.values_over_time.map(item => ({
                  date: item.date,
                  value: item.value,
                  status: item.status,
                  performed_at: item.date
                }));

                return (
                  <div key={trend.exam_type.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                      <div className="bg-blue-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-blue-900">Último Valor</p>
                        <p className="text-lg font-bold text-blue-900">
                          {trend.latest_value} {trend.exam_type.unit}
                        </p>
                        <p className="text-xs text-blue-600">
                          {new Date(trend.latest_date).toLocaleDateString('pt-BR')}
                        </p>
                      </div>
                      <div className="bg-green-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-green-900">Média</p>
                        <p className="text-lg font-bold text-green-900">
                          {trend.average_value.toFixed(1)} {trend.exam_type.unit}
                        </p>
                      </div>
                      <div className="bg-gray-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-gray-900">Total de Resultados</p>
                        <p className="text-lg font-bold text-gray-900">{trend.results_count}</p>
                      </div>
                    </div>
                    <ResultsChart 
                      data={chartData}
                      examType={trend.exam_type}
                      title={`${trend.exam_type.name} - Evolução`}
                    />
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-8 bg-gray-50 rounded-lg">
              <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Sem dados para tendências</h3>
              <p className="mt-1 text-sm text-gray-500">
                Este paciente ainda não possui resultados suficientes para gerar gráficos de tendência
              </p>
            </div>
          )}
        </div>
      )}

      {/* Lista de Resultados */}
      {currentResults.length > 0 ? (
        <div className="card">
          <div className="overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Paciente
                  </th>
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
                {currentResults.map((result) => (
                  <tr key={result.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <UserIcon className="h-5 w-5 text-gray-400 mr-3" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {result.patient.name}
                          </div>
                          <div className="text-sm text-gray-500">{result.patient.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <BeakerIcon className="h-5 w-5 text-gray-400 mr-3" />
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
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <CalendarIcon className="h-4 w-4 text-gray-400 mr-2" />
                        <div className="text-sm text-gray-900">
                          {new Date(result.performed_at).toLocaleDateString('pt-BR')}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {result.lab_technician.name}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Paginação */}
          {totalPages > 1 && (
            <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
              <div className="flex-1 flex justify-between sm:hidden">
                <button
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1}
                  className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Anterior
                </button>
                <button
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={currentPage === totalPages}
                  className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Próxima
                </button>
              </div>
              <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                <div>
                  <p className="text-sm text-gray-700">
                    Mostrando{' '}
                    <span className="font-medium">{startIndex + 1}</span>
                    {' '}a{' '}
                    <span className="font-medium">{Math.min(endIndex, filteredResults.length)}</span>
                    {' '}de{' '}
                    <span className="font-medium">{filteredResults.length}</span>
                    {' '}resultados
                  </p>
                </div>
                <div>
                  <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                    <button
                      onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                      disabled={currentPage === 1}
                      className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Anterior
                    </button>
                    
                    {/* Números das páginas */}
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                      const pageNumber = Math.max(1, Math.min(currentPage - 2 + i, totalPages - 4 + i));
                      return (
                        <button
                          key={pageNumber}
                          onClick={() => setCurrentPage(pageNumber)}
                          className={`relative inline-flex items-center px-4 py-2 border text-sm font-medium ${
                            currentPage === pageNumber
                              ? 'z-10 bg-primary-50 border-primary-500 text-primary-600'
                              : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
                          }`}
                        >
                          {pageNumber}
                        </button>
                      );
                    })}
                    
                    <button
                      onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                      disabled={currentPage === totalPages}
                      className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Próxima
                    </button>
                  </nav>
                </div>
              </div>
            </div>
          )}
        </div>
      ) : (
        <div className="card text-center py-12">
          <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            {results.length === 0 ? 'Nenhum resultado encontrado' : 'Nenhum resultado corresponde aos filtros'}
          </h3>
          <p className="mt-1 text-sm text-gray-500">
            {results.length === 0 
              ? 'Seus pacientes ainda não possuem resultados de exames.'
              : 'Tente ajustar os filtros para ver mais resultados.'
            }
          </p>
        </div>
      )}

      {/* Informações sobre Exportação */}
      <div className="card bg-blue-50 border-blue-200">
        <div className="flex items-center mb-4">
          <ExclamationTriangleIcon className="h-6 w-6 text-blue-600 mr-2" />
          <h3 className="text-lg font-medium text-blue-900">Informações sobre Exportação CSV</h3>
        </div>
        <div className="text-sm text-blue-700 space-y-2">
          <p><strong>Exportar Paciente:</strong> Exporta apenas os resultados do paciente selecionado nos filtros</p>
          <p><strong>Exportar Todos:</strong> Exporta todos os resultados de seus pacientes, respeitando os filtros ativos</p>
          <p><strong>Filtros aplicados:</strong> Os filtros de tipo de exame e data são aplicados na exportação</p>
          <p><strong>Formato:</strong> CSV com informações completas incluindo referências e status dos resultados</p>
          <p className="mt-4 font-medium">
            💡 <strong>Dica:</strong> Use os filtros para exportar dados específicos por período ou tipo de exame
          </p>
        </div>
      </div>
    </div>
  );
};

export default DoctorResults;