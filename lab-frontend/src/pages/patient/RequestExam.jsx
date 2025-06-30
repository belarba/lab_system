import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { 
  BeakerIcon, 
  CalendarIcon, 
  InformationCircleIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';

const RequestExam = () => {
  const { user } = useAuth();
  const { request, loading } = useApi();
  
  const [examTypes, setExamTypes] = useState([]);
  const [recentRequests, setRecentRequests] = useState([]);
  const [loadingData, setLoadingData] = useState(true);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  
  const [formData, setFormData] = useState({
    exam_type_id: '',
    scheduled_date: '',
    notes: ''
  });

  const fetchData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar tipos de exame disponíveis
      const typesResponse = await request({
        method: 'GET',
        url: '/exam_types'
      });
      
      if (typesResponse.data) {
        setExamTypes(typesResponse.data.exam_types || []);
      }

      // Buscar requisições recentes para verificar limitações
      const requestsResponse = await request({
        method: 'GET',
        url: `/patients/${user.id}/blood_work_requests?limit=10`
      });
      
      if (requestsResponse.data) {
        setRecentRequests(requestsResponse.data.blood_work_requests || []);
      }
      
    } catch (error) {
      console.error('Erro ao buscar dados:', error);
      setError('Erro ao carregar dados. Tente novamente.');
    } finally {
      setLoadingData(false);
    }
  }, [request, user.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Verificar se pode solicitar um tipo específico de exame
  const canRequestExamType = (examTypeId) => {
    if (!examTypeId) return true;
    
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    return !recentRequests.some(req => 
      req.exam_type.id.toString() === examTypeId.toString() &&
      new Date(req.created_at) > oneWeekAgo &&
      req.status !== 'cancelled'
    );
  };

  // Obter data da última solicitação para um tipo específico
  const getLastRequestDate = (examTypeId) => {
    const lastRequest = recentRequests
      .filter(req => 
        req.exam_type.id.toString() === examTypeId.toString() &&
        req.status !== 'cancelled'
      )
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))[0];
    
    return lastRequest ? new Date(lastRequest.created_at) : null;
  };

  // Calcular quando poderá solicitar novamente
  const getNextRequestDate = (examTypeId) => {
    const lastDate = getLastRequestDate(examTypeId);
    if (!lastDate) return null;
    
    const nextDate = new Date(lastDate);
    nextDate.setDate(nextDate.getDate() + 7);
    return nextDate;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Limpar mensagens ao mudar campos
    if (error) setError('');
    if (success) setSuccess('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    // Validações
    if (!formData.exam_type_id) {
      setError('Por favor, selecione um tipo de exame');
      return;
    }

    if (!formData.scheduled_date) {
      setError('Por favor, selecione uma data preferida');
      return;
    }

    // Verificar se pode solicitar este tipo de exame
    if (!canRequestExamType(formData.exam_type_id)) {
      const nextDate = getNextRequestDate(formData.exam_type_id);
      setError(`Você já solicitou este tipo de exame recentemente. Poderá solicitar novamente em ${nextDate.toLocaleDateString('pt-BR')}`);
      return;
    }

    // Verificar se a data é futura
    const selectedDate = new Date(formData.scheduled_date);
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    if (selectedDate < tomorrow) {
      setError('A data deve ser pelo menos amanhã');
      return;
    }

    try {
      const response = await request({
        method: 'POST',
        url: '/patient/requests',
        data: {
          exam_type_id: formData.exam_type_id,
          scheduled_date: formData.scheduled_date,
          notes: formData.notes
        }
      });

      if (response.data && !response.error) {
        setSuccess('Exame solicitado com sucesso! Você receberá confirmação em breve.');
        
        // Limpar formulário
        setFormData({
          exam_type_id: '',
          scheduled_date: '',
          notes: ''
        });
        
        // Recarregar dados para atualizar limitações
        fetchData();
        
        // Limpar mensagem de sucesso após 5 segundos
        setTimeout(() => setSuccess(''), 5000);
      } else {
        setError(response.error || 'Erro ao solicitar exame');
      }
    } catch {
      setError('Erro ao solicitar exame. Tente novamente.');
    }
  };

  // Data mínima é amanhã
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const minDate = tomorrow.toISOString().split('T')[0];

  // Data máxima é 3 meses no futuro
  const maxDate = new Date();
  maxDate.setMonth(maxDate.getMonth() + 3);
  const maxDateStr = maxDate.toISOString().split('T')[0];

  if (loadingData) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Solicitar Exame Laboratorial</h1>
        <p className="text-gray-600">Solicite seus exames de forma rápida e segura</p>
      </div>

      {/* Mensagens de feedback */}
      {success && (
        <div className="bg-green-50 border border-green-200 rounded-md p-4">
          <div className="flex">
            <CheckCircleIcon className="h-5 w-5 text-green-400" />
            <div className="ml-3">
              <p className="text-sm font-medium text-green-800">{success}</p>
            </div>
          </div>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <ExclamationTriangleIcon className="h-5 w-5 text-red-400" />
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{error}</p>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Formulário */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="flex items-center mb-6">
              <BeakerIcon className="h-8 w-8 text-primary-600 mr-3" />
              <h2 className="text-xl font-semibold text-gray-900">Nova Solicitação</h2>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Tipo de Exame */}
              <div>
                <label htmlFor="exam_type_id" className="block text-sm font-medium text-gray-700 mb-2">
                  Tipo de Exame *
                </label>
                <select
                  id="exam_type_id"
                  name="exam_type_id"
                  value={formData.exam_type_id}
                  onChange={handleChange}
                  required
                  className="input-field"
                >
                  <option value="">Selecione um tipo de exame</option>
                  {examTypes.map(examType => {
                    const canRequest = canRequestExamType(examType.id);
                    const nextDate = getNextRequestDate(examType.id);
                    
                    return (
                      <option 
                        key={examType.id} 
                        value={examType.id}
                        disabled={!canRequest}
                      >
                        {examType.name} - {examType.description}
                        {!canRequest && nextDate && ` (Disponível em ${nextDate.toLocaleDateString('pt-BR')})`}
                      </option>
                    );
                  })}
                </select>
                
                {formData.exam_type_id && (
                  <div className="mt-2">
                    {canRequestExamType(formData.exam_type_id) ? (
                      <p className="text-sm text-green-600 flex items-center">
                        <CheckCircleIcon className="h-4 w-4 mr-1" />
                        Disponível para solicitação
                      </p>
                    ) : (
                      <p className="text-sm text-red-600 flex items-center">
                        <ExclamationTriangleIcon className="h-4 w-4 mr-1" />
                        Já solicitado recentemente
                      </p>
                    )}
                  </div>
                )}
              </div>

              {/* Data Preferida */}
              <div>
                <label htmlFor="scheduled_date" className="block text-sm font-medium text-gray-700 mb-2">
                  <CalendarIcon className="h-4 w-4 inline mr-1" />
                  Data Preferida *
                </label>
                <input
                  type="date"
                  id="scheduled_date"
                  name="scheduled_date"
                  value={formData.scheduled_date}
                  onChange={handleChange}
                  min={minDate}
                  max={maxDateStr}
                  required
                  className="input-field"
                />
                <p className="mt-1 text-sm text-gray-500">
                  Selecione a data preferida para realização do exame (mínimo: amanhã)
                </p>
              </div>

              {/* Observações */}
              <div>
                <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
                  Observações (Opcional)
                </label>
                <textarea
                  id="notes"
                  name="notes"
                  value={formData.notes}
                  onChange={handleChange}
                  rows={4}
                  className="input-field"
                  placeholder="Informações adicionais, condições especiais, etc."
                />
              </div>

              {/* Botão de Envio */}
              <div className="pt-4">
                <button
                  type="submit"
                  disabled={loading || !canRequestExamType(formData.exam_type_id)}
                  className="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                >
                  {loading ? (
                    <>
                      <LoadingSpinner size="sm" className="mr-2" />
                      Processando...
                    </>
                  ) : (
                    'Solicitar Exame'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Informações e Orientações */}
        <div className="space-y-6">
          {/* Informações Importantes */}
          <div className="card bg-blue-50 border-blue-200">
            <div className="flex items-center mb-4">
              <InformationCircleIcon className="h-6 w-6 text-blue-600 mr-2" />
              <h3 className="text-lg font-medium text-blue-900">Informações Importantes</h3>
            </div>
            <div className="text-sm text-blue-700 space-y-2">
              <p>• <strong>Limite:</strong> 1 exame por tipo a cada 7 dias</p>
              <p>• <strong>Agendamento:</strong> Mínimo 24h de antecedência</p>
              <p>• <strong>Cancelamento:</strong> Até 3h antes do exame</p>
              <p>• <strong>Jejum:</strong> Siga orientações específicas quando necessário</p>
              <p>• <strong>Resultados:</strong> Disponíveis em 24-48h após coleta</p>
            </div>
          </div>

          {/* Exames Disponíveis */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Exames Disponíveis</h3>
            <div className="space-y-3">
              {examTypes.map(examType => {
                const canRequest = canRequestExamType(examType.id);
                const nextDate = getNextRequestDate(examType.id);
                
                return (
                  <div key={examType.id} className="border border-gray-200 rounded-lg p-3">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <h4 className="text-sm font-medium text-gray-900">{examType.name}</h4>
                        <p className="text-xs text-gray-500 mt-1">{examType.description}</p>
                        <p className="text-xs text-gray-400">Unidade: {examType.unit}</p>
                        {examType.reference_range && (
                          <p className="text-xs text-gray-400">Referência: {examType.reference_range}</p>
                        )}
                      </div>
                      <div className="ml-3">
                        {canRequest ? (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            Disponível
                          </span>
                        ) : (
                          <div className="text-right">
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                              Bloqueado
                            </span>
                            {nextDate && (
                              <p className="text-xs text-gray-500 mt-1">
                                Até {nextDate.toLocaleDateString('pt-BR')}
                              </p>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Orientações de Preparo */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Orientações Gerais</h3>
            <div className="text-sm text-gray-600 space-y-2">
              <p><strong>Jejum:</strong> Alguns exames podem exigir jejum de 8-12 horas</p>
              <p><strong>Medicamentos:</strong> Informe sobre medicamentos em uso</p>
              <p><strong>Hidratação:</strong> Beba água normalmente, salvo orientação contrária</p>
              <p><strong>Documentos:</strong> Traga documento de identificação</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestExam;