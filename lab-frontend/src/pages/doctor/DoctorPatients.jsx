import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import AddPatientModal from '../../components/modals/AddPatientModal';
import {
  UsersIcon,
  FunnelIcon,
  XMarkIcon,
  ChartBarIcon,
  DocumentTextIcon,
  CalendarIcon,
  MagnifyingGlassIcon,
  UserCircleIcon,
  PlusIcon
} from '@heroicons/react/24/outline';

const DoctorPatients = () => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [patients, setPatients] = useState([]);
  const [filteredPatients, setFilteredPatients] = useState([]);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [patientDetails, setPatientDetails] = useState(null);
  const [loadingData, setLoadingData] = useState(true);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  
  // Estados de filtro
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [sortOrder, setSortOrder] = useState('asc');

  const fetchPatients = useCallback(async () => {
    try {
      setLoadingData(true);
      
      const response = await request({
        method: 'GET',
        url: `/doctors/${user.id}/patients`
      });
      
      if (response.data) {
        const patientsList = response.data.patients || [];
        setPatients(patientsList);
        setFilteredPatients(patientsList);
      }
      
    } catch (error) {
      console.error('Erro ao buscar pacientes:', error);
    } finally {
      setLoadingData(false);
    }
  }, [request, user.id]);

  const fetchPatientDetails = async (patientId) => {
    try {
      setLoadingDetails(true);
      
      const response = await request({
        method: 'GET',
        url: `/patients/${patientId}`
      });
      
      if (response.data) {
        setPatientDetails(response.data.patient);
      }
      
    } catch (error) {
      console.error('Erro ao buscar detalhes do paciente:', error);
    } finally {
      setLoadingDetails(false);
    }
  };

  useEffect(() => {
    fetchPatients();
  }, [fetchPatients]);

  // Aplicar filtros e ordenação
  useEffect(() => {
    let filtered = [...patients];

    // Filtro por termo de busca
    if (searchTerm) {
      filtered = filtered.filter(patient =>
        patient.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        patient.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (patient.phone && patient.phone.includes(searchTerm))
      );
    }

    // Ordenação
    filtered.sort((a, b) => {
      let valueA, valueB;
      
      switch (sortBy) {
        case 'name':
          valueA = a.name.toLowerCase();
          valueB = b.name.toLowerCase();
          break;
        case 'email':
          valueA = a.email.toLowerCase();
          valueB = b.email.toLowerCase();
          break;
        case 'recent_requests_count':
          valueA = a.recent_requests_count || 0;
          valueB = b.recent_requests_count || 0;
          break;
        case 'total_results':
          valueA = a.total_results || 0;
          valueB = b.total_results || 0;
          break;
        case 'last_request_date':
          valueA = a.last_request_date ? new Date(a.last_request_date) : new Date(0);
          valueB = b.last_request_date ? new Date(b.last_request_date) : new Date(0);
          break;
        default:
          valueA = a.name.toLowerCase();
          valueB = b.name.toLowerCase();
      }

      if (sortOrder === 'asc') {
        return valueA > valueB ? 1 : -1;
      } else {
        return valueA < valueB ? 1 : -1;
      }
    });

    setFilteredPatients(filtered);
  }, [patients, searchTerm, sortBy, sortOrder]);

  const handlePatientSelect = (patient) => {
    setSelectedPatient(patient);
    fetchPatientDetails(patient.id);
  };

  const handleAddPatientSuccess = (newPatient) => {
    setPatients(prev => [newPatient, ...prev]);
    setShowAddModal(false);
  };

  const clearSearch = () => {
    setSearchTerm('');
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
          <h1 className="text-2xl font-bold text-gray-900">Meus Pacientes</h1>
          <p className="text-gray-600">Gerencie e acompanhe seus pacientes</p>
        </div>
        <div className="flex items-center space-x-3">
          <div className="text-sm text-gray-500">
            {filteredPatients.length} de {patients.length} pacientes
          </div>
          <button
            onClick={() => setShowAddModal(true)}
            className="btn-primary flex items-center"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            Adicionar Paciente
          </button>
        </div>
      </div>

      {/* Modal de Adicionar Paciente */}
      <AddPatientModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        onSuccess={handleAddPatientSuccess}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Lista de Pacientes */}
        <div className="lg:col-span-2 space-y-4">
          {/* Controles de Filtro e Busca */}
          <div className="card">
            <div className="space-y-4">
              {/* Busca */}
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <MagnifyingGlassIcon className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="text"
                  placeholder="Buscar por nome, email ou telefone..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="block w-full pl-10 pr-10 input-field"
                />
                {searchTerm && (
                  <button
                    onClick={clearSearch}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  >
                    <XMarkIcon className="h-5 w-5 text-gray-400 hover:text-gray-600" />
                  </button>
                )}
              </div>

              {/* Controles de Ordenação */}
              <div className="flex flex-wrap gap-4">
                <div className="flex items-center space-x-2">
                  <label className="text-sm font-medium text-gray-700">Ordenar por:</label>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value)}
                    className="text-sm border-gray-300 rounded-md"
                  >
                    <option value="name">Nome</option>
                    <option value="email">Email</option>
                    <option value="recent_requests_count">Nº Exames</option>
                    <option value="total_results">Resultados</option>
                    <option value="last_request_date">Último Exame</option>
                  </select>
                </div>
                <div className="flex items-center space-x-2">
                  <label className="text-sm font-medium text-gray-700">Ordem:</label>
                  <select
                    value={sortOrder}
                    onChange={(e) => setSortOrder(e.target.value)}
                    className="text-sm border-gray-300 rounded-md"
                  >
                    <option value="asc">Crescente</option>
                    <option value="desc">Decrescente</option>
                  </select>
                </div>
              </div>
            </div>
          </div>

          {/* Lista de Pacientes */}
          {filteredPatients.length > 0 ? (
            <div className="space-y-3">
              {filteredPatients.map((patient) => (
                <div
                  key={patient.id}
                  onClick={() => handlePatientSelect(patient)}
                  className={`card cursor-pointer transition-colors ${
                    selectedPatient?.id === patient.id
                      ? 'bg-primary-50 border-primary-200'
                      : 'hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <UserCircleIcon className="h-12 w-12 text-gray-400" />
                      <div>
                        <h3 className="text-lg font-medium text-gray-900">{patient.name}</h3>
                        <p className="text-sm text-gray-500">{patient.email}</p>
                        {patient.phone && (
                          <p className="text-sm text-gray-500">{patient.phone}</p>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="grid grid-cols-2 gap-4 text-center">
                        <div>
                          <p className="text-2xl font-bold text-primary-600">
                            {patient.recent_requests_count || 0}
                          </p>
                          <p className="text-xs text-gray-500">Exames</p>
                        </div>
                        <div>
                          <p className="text-2xl font-bold text-green-600">
                            {patient.total_results || 0}
                          </p>
                          <p className="text-xs text-gray-500">Resultados</p>
                        </div>
                      </div>
                      {patient.last_request_date && (
                        <p className="text-xs text-gray-400 mt-2">
                          Último: {new Date(patient.last_request_date).toLocaleDateString('pt-BR')}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="card text-center py-12">
              <UsersIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">
                {searchTerm ? 'Nenhum paciente encontrado' : 'Nenhum paciente cadastrado'}
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                {searchTerm 
                  ? 'Tente ajustar os termos de busca.'
                  : 'Você ainda não possui pacientes. Comece adicionando seu primeiro paciente.'
                }
              </p>
              {!searchTerm && (
                <div className="mt-6">
                  <button
                    onClick={() => setShowAddModal(true)}
                    className="btn-primary"
                  >
                    Adicionar Primeiro Paciente
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Detalhes do Paciente Selecionado */}
        <div className="space-y-4">
          {selectedPatient ? (
            <>
              {/* Informações Básicas */}
              <div className="card">
                <div className="flex items-center mb-4">
                  <UserCircleIcon className="h-8 w-8 text-primary-600 mr-3" />
                  <h2 className="text-xl font-semibold text-gray-900">Detalhes do Paciente</h2>
                </div>

                {loadingDetails ? (
                  <div className="flex justify-center py-4">
                    <LoadingSpinner size="md" />
                  </div>
                ) : patientDetails ? (
                  <div className="space-y-4">
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">{patientDetails.name}</h3>
                      <p className="text-sm text-gray-500">{patientDetails.email}</p>
                      {patientDetails.phone && (
                        <p className="text-sm text-gray-500">{patientDetails.phone}</p>
                      )}
                    </div>

                    {/* Estatísticas */}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-blue-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-blue-900">Total de Exames</p>
                        <p className="text-xl font-bold text-blue-900">
                          {patientDetails.statistics?.total_requests || 0}
                        </p>
                      </div>
                      <div className="bg-green-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-green-900">Resultados</p>
                        <p className="text-xl font-bold text-green-900">
                          {patientDetails.statistics?.completed_requests || 0}
                        </p>
                      </div>
                      <div className="bg-yellow-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-yellow-900">Pendentes</p>
                        <p className="text-xl font-bold text-yellow-900">
                          {patientDetails.statistics?.pending_requests || 0}
                        </p>
                      </div>
                      <div className="bg-purple-50 p-3 rounded-lg">
                        <p className="text-sm font-medium text-purple-900">Tipos Únicos</p>
                        <p className="text-xl font-bold text-purple-900">
                          {patientDetails.statistics?.unique_exam_types || 0}
                        </p>
                      </div>
                    </div>

                    {/* Médicos Associados */}
                    {patientDetails.doctors && patientDetails.doctors.length > 0 && (
                      <div>
                        <h4 className="text-sm font-medium text-gray-900 mb-2">Outros Médicos</h4>
                        <div className="space-y-1">
                          {patientDetails.doctors
                            .filter(doctor => doctor.id !== user.id)
                            .map(doctor => (
                              <p key={doctor.id} className="text-sm text-gray-600">
                                Dr. {doctor.name}
                              </p>
                            ))}
                        </div>
                      </div>
                    )}

                    {/* Data do último resultado */}
                    {patientDetails.statistics?.last_result_date && (
                      <div>
                        <p className="text-sm font-medium text-gray-900">Último Resultado</p>
                        <p className="text-sm text-gray-600">
                          {new Date(patientDetails.statistics.last_result_date).toLocaleDateString('pt-BR')}
                        </p>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-gray-500">Erro ao carregar detalhes do paciente</p>
                )}
              </div>

              {/* Ações Rápidas */}
              <div className="space-y-3">
                <a
                  href={`/doctor/exams?patient=${selectedPatient.id}`}
                  className="w-full btn-primary text-center block"
                >
                  <DocumentTextIcon className="h-4 w-4 inline mr-2" />
                  Ver Exames
                </a>
                <a
                  href={`/doctor/results?patient=${selectedPatient.id}`}
                  className="w-full btn-secondary text-center block"
                >
                  <ChartBarIcon className="h-4 w-4 inline mr-2" />
                  Ver Resultados
                </a>
              </div>

              {/* Informações do Paciente */}
              <div className="card bg-blue-50 border-blue-200">
                <h4 className="text-sm font-medium text-blue-900 mb-2">
                  Informações do Paciente
                </h4>
                <div className="text-sm text-blue-700 space-y-1">
                  <p>• Membro desde: {new Date(selectedPatient.created_at || Date.now()).toLocaleDateString('pt-BR')}</p>
                  <p>• ID do Paciente: #{selectedPatient.id}</p>
                  <p>• Status: Ativo</p>
                </div>
              </div>
            </>
          ) : (
            <div className="card text-center py-12">
              <UserCircleIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Selecione um Paciente</h3>
              <p className="mt-1 text-sm text-gray-500">
                Clique em um paciente da lista para ver os detalhes
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default DoctorPatients;