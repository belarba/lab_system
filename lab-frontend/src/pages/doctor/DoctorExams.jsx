import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import RequestExamForm from '../../components/forms/RequestExamForm';
import {
  ClipboardDocumentListIcon,
  PlusIcon,
  FunnelIcon,
  XMarkIcon,
  BeakerIcon,
  CalendarIcon,
  UserIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  EyeIcon
} from '@heroicons/react/24/outline';

const DoctorExams = () => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [exams, setExams] = useState([]);
  const [filteredExams, setFilteredExams] = useState([]);
  const [examTypes, setExamTypes] = useState([]);
  const [patients, setPatients] = useState([]);
  const [loadingData, setLoadingData] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [cancellingExam, setCancellingExam] = useState(null);
  
  // Estados de filtro
  const [filters, setFilters] = useState({
    status: '',
    examType: '',
    patient: '',
    dateFrom: '',
    dateTo: ''
  });

  // Estados de paginação
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  const fetchData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar exames do médico
      const examsResponse = await request({
        method: 'GET',
        url: `/doctors/${user.id}/blood_work_requests`
      });
      
      if (examsResponse.data) {
        const examsList = examsResponse.data.blood_work_requests || [];
        setExams(examsList);
        setFilteredExams(examsList);
      }

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
      
    } catch (error) {
      console.error('Erro ao buscar dados:', error);
    } finally {
      setLoadingData(false);
    }
  }, [request, user.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Aplicar filtros
  useEffect(() => {
    let filtered = [...exams];

    if (filters.status) {
      filtered = filtered.filter(exam => exam.status === filters.status);
    }

    if (filters.examType) {
      filtered = filtered.filter(exam => exam.exam_type.id.toString() === filters.examType);
    }

    if (filters.patient) {
      filtered = filtered.filter(exam => exam.patient.id.toString() === filters.patient);
    }

    if (filters.dateFrom) {
      filtered = filtered.filter(exam => 
        new Date(exam.scheduled_date) >= new Date(filters.dateFrom)
      );
    }

    if (filters.dateTo) {
      filtered = filtered.filter(exam => 
        new Date(exam.scheduled_date) <= new Date(filters.dateTo)
      );
    }

    // Ordenar por data agendada (mais recentes primeiro)
    filtered.sort((a, b) => new Date(b.scheduled_date) - new Date(a.scheduled_date));

    setFilteredExams(filtered);
    setCurrentPage(1); // Reset para primeira página ao filtrar
  }, [filters, exams]);

  const handleFilterChange = (field, value) => {
    setFilters(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const clearFilters = () => {
    setFilters({
      status: '',
      examType: '',
      patient: '',
      dateFrom: '',
      dateTo: ''
    });
  };

  const handleCreateSuccess = (newExam) => {
    setExams(prev => [newExam.exam_request || newExam.blood_work_request || newExam, ...prev]);
    setShowCreateForm(false);
    alert('Exame solicitado com sucesso!');
  };

  const handleCancelExam = async (examId) => {
    if (!confirm('Tem certeza que deseja cancelar este exame?')) {
      return;
    }

    try {
      setCancellingExam(examId);
      
      const response = await request({
        method: 'POST',
        url: `/blood_work_requests/${examId}/cancel`
      });

      if (response.data && !response.error) {
        // Atualizar lista local
        setExams(prev => prev.map(exam => 
          exam.id === examId 
            ? { ...exam, status: 'cancelled' }
            : exam
        ));
        
        alert('Exame cancelado com sucesso!');
      } else {
        alert('Erro ao cancelar exame: ' + (response.error || 'Erro desconhecido'));
      }
    } catch {
      alert('Erro ao cancelar exame');
    } finally {
      setCancellingExam(null);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'scheduled':
        return <ClockIcon className="h-5 w-5 text-blue-500" />;
      case 'completed':
        return <CheckCircleIcon className="h-5 w-5 text-green-500" />;
      case 'cancelled':
        return <XCircleIcon className="h-5 w-5 text-red-500" />;
      default:
        return <BeakerIcon className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'scheduled':
        return 'Agendado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      case 'pending':
        return 'Pendente';
      default:
        return status;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'scheduled':
        return 'bg-blue-100 text-blue-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const canCancelExam = (exam) => {
    return exam.status === 'scheduled' || exam.status === 'pending';
  };

  // Paginação
  const totalPages = Math.ceil(filteredExams.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentExams = filteredExams.slice(startIndex, endIndex);

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
          <h1 className="text-2xl font-bold text-gray-900">Solicitações de Exames</h1>
          <p className="text-gray-600">Gerencie solicitações de exames para seus pacientes</p>
        </div>
        <button
          onClick={() => setShowCreateForm(true)}
          className="btn-primary flex items-center"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Nova Solicitação
        </button>
      </div>

      {/* Modal de Criação */}
      {showCreateForm && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 max-w-4xl shadow-lg rounded-md bg-white">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-900">Nova Solicitação de Exame</h2>
              <button
                onClick={() => setShowCreateForm(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XMarkIcon className="h-6 w-6" />
              </button>
            </div>
            <RequestExamForm
              onSuccess={handleCreateSuccess}
              onCancel={() => setShowCreateForm(false)}
            />
          </div>
        </div>
      )}

      {/* Estatísticas Rápidas */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center">
            <ClipboardDocumentListIcon className="h-8 w-8 text-gray-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Total</p>
              <p className="text-2xl font-bold text-gray-900">{exams.length}</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <ClockIcon className="h-8 w-8 text-blue-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Agendados</p>
              <p className="text-2xl font-bold text-blue-900">
                {exams.filter(e => e.status === 'scheduled').length}
              </p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <CheckCircleIcon className="h-8 w-8 text-green-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Concluídos</p>
              <p className="text-2xl font-bold text-green-900">
                {exams.filter(e => e.status === 'completed').length}
              </p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center">
            <XCircleIcon className="h-8 w-8 text-red-400" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Cancelados</p>
              <p className="text-2xl font-bold text-red-900">
                {exams.filter(e => e.status === 'cancelled').length}
              </p>
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
              Status
            </label>
            <select
              value={filters.status}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="input-field"
            >
              <option value="">Todos os status</option>
              <option value="scheduled">Agendado</option>
              <option value="completed">Concluído</option>
              <option value="cancelled">Cancelado</option>
              <option value="pending">Pendente</option>
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

        {(filters.status || filters.examType || filters.patient || filters.dateFrom || filters.dateTo) && (
          <div className="mt-4 flex justify-between items-center">
            <p className="text-sm text-gray-600">
              Mostrando {filteredExams.length} de {exams.length} exames
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

      {/* Lista de Exames */}
      {currentExams.length > 0 ? (
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
                    Data Agendada
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Resultado
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Criado em
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ações
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {currentExams.map((exam) => (
                  <tr key={exam.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <UserIcon className="h-5 w-5 text-gray-400 mr-3" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {exam.patient.name}
                          </div>
                          <div className="text-sm text-gray-500">{exam.patient.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <BeakerIcon className="h-5 w-5 text-gray-400 mr-3" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {exam.exam_type.name}
                          </div>
                          <div className="text-sm text-gray-500">
                            {exam.exam_type.unit}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <CalendarIcon className="h-4 w-4 text-gray-400 mr-2" />
                        <div className="text-sm text-gray-900">
                          {new Date(exam.scheduled_date).toLocaleDateString('pt-BR')}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {getStatusIcon(exam.status)}
                        <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(exam.status)}`}>
                          {getStatusText(exam.status)}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {exam.result ? (
                        <div>
                          <span className="font-medium">{exam.result.value} {exam.result.unit}</span>
                          <br />
                          <span className="text-xs text-gray-500">
                            {new Date(exam.result.performed_at).toLocaleDateString('pt-BR')}
                          </span>
                        </div>
                      ) : (
                        <span className="text-gray-400">Aguardando</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(exam.created_at).toLocaleDateString('pt-BR')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex justify-end space-x-2">
                        <a
                          href={`/doctor/results?patient=${exam.patient.id}&exam=${exam.id}`}
                          className="text-primary-600 hover:text-primary-900"
                          title="Ver detalhes"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </a>
                        {canCancelExam(exam) && (
                          <button
                            onClick={() => handleCancelExam(exam.id)}
                            disabled={cancellingExam === exam.id}
                            className="text-red-600 hover:text-red-900 disabled:opacity-50 disabled:cursor-not-allowed"
                            title="Cancelar exame"
                          >
                            {cancellingExam === exam.id ? (
                              <LoadingSpinner size="sm" />
                            ) : (
                              <XMarkIcon className="h-4 w-4" />
                            )}
                          </button>
                        )}
                      </div>
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
                    <span className="font-medium">{Math.min(endIndex, filteredExams.length)}</span>
                    {' '}de{' '}
                    <span className="font-medium">{filteredExams.length}</span>
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
          <ClipboardDocumentListIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            {exams.length === 0 ? 'Nenhum exame encontrado' : 'Nenhum exame corresponde aos filtros'}
          </h3>
          <p className="mt-1 text-sm text-gray-500">
            {exams.length === 0 
              ? 'Você ainda não possui exames solicitados.'
              : 'Tente ajustar os filtros para ver mais resultados.'
            }
          </p>
          {exams.length === 0 && (
            <div className="mt-6">
              <button
                onClick={() => setShowCreateForm(true)}
                className="btn-primary"
              >
                Criar Primeira Solicitação
              </button>
            </div>
          )}
        </div>
      )}

      {/* Informações sobre Cancelamento */}
      <div className="card bg-blue-50 border-blue-200">
        <h3 className="text-sm font-medium text-blue-900 mb-2">Informações sobre Solicitações</h3>
        <div className="text-sm text-blue-700 space-y-1">
          <p>• Como médico, você pode solicitar exames ilimitados para seus pacientes</p>
          <p>• Exames podem ser cancelados a qualquer momento antes da realização</p>
          <p>• Pacientes podem cancelar até 3 horas antes do horário agendado</p>
          <p>• Resultados ficam disponíveis automaticamente após processamento</p>
        </div>
      </div>
    </div>
  );
};

export default DoctorExams;