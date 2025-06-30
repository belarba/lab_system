import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  BeakerIcon,
  CalendarIcon,
  FunnelIcon,
  XMarkIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon
} from '@heroicons/react/24/outline';

const PatientExams = () => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [exams, setExams] = useState([]);
  const [filteredExams, setFilteredExams] = useState([]);
  const [examTypes, setExamTypes] = useState([]);
  const [loadingData, setLoadingData] = useState(true);
  const [cancellingExam, setCancellingExam] = useState(null);
  
  // Estados de filtro
  const [filters, setFilters] = useState({
    status: '',
    examType: '',
    dateFrom: '',
    dateTo: ''
  });

  const fetchData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar exames do paciente
      const examsResponse = await request({
        method: 'GET',
        url: `/patients/${user.id}/blood_work_requests`
      });
      
      if (examsResponse.data) {
        const examsList = examsResponse.data.blood_work_requests || [];
        setExams(examsList);
        setFilteredExams(examsList);
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

    setFilteredExams(filtered);
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
      dateFrom: '',
      dateTo: ''
    });
  };

  const canCancelExam = (exam) => {
    if (exam.status !== 'scheduled') return false;
    
    const examDate = new Date(exam.scheduled_date);
    const now = new Date();
    const diffHours = (examDate - now) / (1000 * 60 * 60);
    
    return diffHours > 3; // Pode cancelar se faltam mais de 3 horas
  };

  const handleCancelExam = async (examId) => {
    try {
      setCancellingExam(examId);
      
      const response = await request({
        method: 'POST',
        url: `/patient/requests/${examId}/cancel`
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
          <h1 className="text-2xl font-bold text-gray-900">Meus Exames</h1>
          <p className="text-gray-600">Acompanhe seus exames laboratoriais</p>
        </div>
        <a href="/patient/request" className="btn-primary">
          Solicitar Novo Exame
        </a>
      </div>

      {/* Filtros */}
      <div className="card">
        <div className="flex items-center mb-4">
          <FunnelIcon className="h-5 w-5 text-gray-400 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Filtros</h3>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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

        {(filters.status || filters.examType || filters.dateFrom || filters.dateTo) && (
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
      {filteredExams.length > 0 ? (
        <div className="card">
          <div className="overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Exame
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Médico
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
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ações
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredExams.map((exam) => (
                  <tr key={exam.id} className="hover:bg-gray-50">
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
                      <div className="text-sm text-gray-900">{exam.doctor.name}</div>
                      <div className="text-sm text-gray-500">{exam.doctor.email}</div>
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
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      {canCancelExam(exam) ? (
                        <button
                          onClick={() => handleCancelExam(exam.id)}
                          disabled={cancellingExam === exam.id}
                          className="text-red-600 hover:text-red-900 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          {cancellingExam === exam.id ? (
                            <LoadingSpinner size="sm" />
                          ) : (
                            'Cancelar'
                          )}
                        </button>
                      ) : exam.status === 'scheduled' ? (
                        <span className="text-gray-400 text-xs">
                          Não pode cancelar<br />
                          (menos de 3h)
                        </span>
                      ) : (
                        <span className="text-gray-400">-</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="card text-center py-12">
          <BeakerIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            {exams.length === 0 ? 'Nenhum exame encontrado' : 'Nenhum exame corresponde aos filtros'}
          </h3>
          <p className="mt-1 text-sm text-gray-500">
            {exams.length === 0 
              ? 'Você ainda não possui exames agendados.'
              : 'Tente ajustar os filtros para ver mais resultados.'
            }
          </p>
          {exams.length === 0 && (
            <div className="mt-6">
              <a href="/patient/request" className="btn-primary">
                Solicitar Primeiro Exame
              </a>
            </div>
          )}
        </div>
      )}

      {/* Informações importantes */}
      <div className="card bg-blue-50 border-blue-200">
        <h3 className="text-sm font-medium text-blue-900 mb-2">Informações sobre Cancelamento</h3>
        <div className="text-sm text-blue-700 space-y-1">
          <p>• Você pode cancelar exames até 3 horas antes do horário agendado</p>
          <p>• Exames concluídos ou já cancelados não podem ser alterados</p>
          <p>• Em caso de emergência, entre em contato conosco</p>
        </div>
      </div>
    </div>
  );
};

export default PatientExams;