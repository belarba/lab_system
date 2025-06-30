import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../common/LoadingSpinner';
import { BeakerIcon, CalendarIcon } from '@heroicons/react/24/outline';

const RequestExamForm = ({ onSuccess, onCancel }) => {
  const { user, hasRole } = useAuth();
  const { request, loading } = useApi();
  
  const [examTypes, setExamTypes] = useState([]);
  const [patients, setPatients] = useState([]);
  const [formData, setFormData] = useState({
    exam_type_id: '',
    patient_id: hasRole('patient') ? user?.id : '',
    scheduled_date: '',
    notes: ''
  });
  const [loadingData, setLoadingData] = useState(true);

  const fetchInitialData = useCallback(async () => {
    try {
      setLoadingData(true);
      
      // Buscar tipos de exame
      const examTypesResponse = await request({ method: 'GET', url: '/exam_types' });
      if (examTypesResponse.data) {
        setExamTypes(examTypesResponse.data.exam_types || []);
      }

      // Se for médico, buscar pacientes
      if (hasRole('doctor')) {
        const patientsResponse = await request({ 
          method: 'GET', 
          url: `/doctors/${user.id}/patients` 
        });
        if (patientsResponse.data) {
          setPatients(patientsResponse.data.patients || []);
        }
      }
    } catch (error) {
      console.error('Erro ao buscar dados iniciais:', error);
    } finally {
      setLoadingData(false);
    }
  }, [request, hasRole, user?.id]);

  useEffect(() => {
    fetchInitialData();
  }, [fetchInitialData]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validações
    if (!formData.exam_type_id) {
      alert('Por favor, selecione um tipo de exame');
      return;
    }

    if (!formData.scheduled_date) {
      alert('Por favor, selecione uma data');
      return;
    }

    try {
      let response;
      
      if (hasRole('patient')) {
        // Paciente solicitando exame para si mesmo
        response = await request({
          method: 'POST',
          url: '/patient/requests',
          data: {
            exam_type_id: formData.exam_type_id,
            scheduled_date: formData.scheduled_date,
            notes: formData.notes
          }
        });
      } else if (hasRole('doctor')) {
        // Médico solicitando exame para paciente
        response = await request({
          method: 'POST',
          url: '/blood_work_requests',
          data: {
            blood_work_request: {
              patient_id: formData.patient_id,
              exam_type_id: formData.exam_type_id,
              scheduled_date: formData.scheduled_date,
              notes: formData.notes
            }
          }
        });
      }

      if (response && !response.error) {
        onSuccess && onSuccess(response.data);
        // Limpar formulário
        setFormData({
          exam_type_id: '',
          patient_id: hasRole('patient') ? user?.id : '',
          scheduled_date: '',
          notes: ''
        });
      }
    } catch (error) {
      console.error('Erro ao solicitar exame:', error);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  if (loadingData) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  // Data mínima é amanhã
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const minDate = tomorrow.toISOString().split('T')[0];

  return (
    <div className="card">
      <div className="flex items-center mb-6">
        <BeakerIcon className="h-8 w-8 text-primary-600 mr-3" />
        <h2 className="text-xl font-semibold text-gray-900">
          Solicitar Exame Laboratorial
        </h2>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Seleção de Paciente (apenas para médicos) */}
        {hasRole('doctor') && (
          <div>
            <label htmlFor="patient_id" className="block text-sm font-medium text-gray-700 mb-2">
              Paciente *
            </label>
            <select
              id="patient_id"
              name="patient_id"
              value={formData.patient_id}
              onChange={handleChange}
              required
              className="input-field"
            >
              <option value="">Selecione um paciente</option>
              {patients.map(patient => (
                <option key={patient.id} value={patient.id}>
                  {patient.name} - {patient.email}
                </option>
              ))}
            </select>
          </div>
        )}

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
            {examTypes.map(examType => (
              <option key={examType.id} value={examType.id}>
                {examType.name} - {examType.description}
              </option>
            ))}
          </select>
        </div>

        {/* Data Agendada */}
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
            required
            className="input-field"
          />
          <p className="mt-1 text-sm text-gray-500">
            Selecione a data preferida para realização do exame
          </p>
        </div>

        {/* Observações */}
        <div>
          <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
            Observações
          </label>
          <textarea
            id="notes"
            name="notes"
            value={formData.notes}
            onChange={handleChange}
            rows={3}
            className="input-field"
            placeholder="Informações adicionais sobre o exame (opcional)"
          />
        </div>

        {/* Informações importantes para pacientes */}
        {hasRole('patient') && (
          <div className="bg-blue-50 p-4 rounded-md">
            <h4 className="text-sm font-medium text-blue-900 mb-2">Informações Importantes:</h4>
            <ul className="text-sm text-blue-700 space-y-1">
              <li>• Você pode solicitar o mesmo tipo de exame apenas uma vez por semana</li>
              <li>• O exame será atribuído automaticamente a um médico disponível</li>
              <li>• Você pode cancelar até 3 horas antes do horário agendado</li>
              <li>• Você receberá os resultados assim que estiverem prontos</li>
            </ul>
          </div>
        )}

        {/* Botões */}
        <div className="flex justify-end space-x-3 pt-4">
          {onCancel && (
            <button
              type="button"
              onClick={onCancel}
              className="btn-secondary"
              disabled={loading}
            >
              Cancelar
            </button>
          )}
          <button
            type="submit"
            disabled={loading}
            className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
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
  );
};

export default RequestExamForm;