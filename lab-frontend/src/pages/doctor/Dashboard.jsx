import React, { useState, useEffect, useCallback } from 'react';
import { Routes, Route } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import api from '../../services/api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  UsersIcon,
  ClipboardDocumentListIcon,
  BeakerIcon,
  DocumentArrowDownIcon
} from '@heroicons/react/24/outline';

const DoctorDashboard = () => {
  return (
    <Routes>
      <Route path="/" element={<DoctorHome />} />
      <Route path="/patients" element={<DoctorPatients />} />
      <Route path="/exams" element={<DoctorExams />} />
      <Route path="/results" element={<DoctorResults />} />
    </Routes>
  );
};

const DoctorHome = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [recentRequests, setRecentRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchDashboardData = useCallback(async () => {
    try {
      setLoading(true);
      
      // Buscar pacientes do médico
      const patientsResponse = await api.get(`/doctors/${user.id}/patients`);
      const patients = patientsResponse.data.patients || [];
      
      // Buscar requisições recentes
      const requestsResponse = await api.get(`/doctors/${user.id}/blood_work_requests?limit=5`);
      const recentReqs = requestsResponse.data.blood_work_requests || [];
      setRecentRequests(recentReqs);
      
      // Buscar todas as requisições para estatísticas
      const allRequestsResponse = await api.get(`/doctors/${user.id}/blood_work_requests`);
      const allRequests = allRequestsResponse.data.blood_work_requests || [];
      
      setStats({
        totalPatients: patients.length,
        totalRequests: allRequests.length,
        pendingRequests: allRequests.filter(req => req.status === 'scheduled').length,
        completedRequests: allRequests.filter(req => req.status === 'completed').length,
      });
      
    } catch (error) {
      console.error('Erro ao buscar dados do dashboard:', error);
    } finally {
      setLoading(false);
    }
  }, [user.id]);

  useEffect(() => {
    fetchDashboardData();
  }, [fetchDashboardData]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const quickActions = [
    {
      name: 'Ver Pacientes',
      description: 'Gerencie sua lista de pacientes',
      href: '/doctor/patients',
      icon: UsersIcon,
      color: 'bg-blue-500 hover:bg-blue-600'
    },
    {
      name: 'Solicitar Exames',
      description: 'Crie novas solicitações de exames',
      href: '/doctor/exams',
      icon: BeakerIcon,
      color: 'bg-green-500 hover:bg-green-600'
    },
    {
      name: 'Ver Resultados',
      description: 'Analise resultados dos pacientes',
      href: '/doctor/results',
      icon: ClipboardDocumentListIcon,
      color: 'bg-purple-500 hover:bg-purple-600'
    }
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Dr. {user?.name}
        </h1>
        <p className="mt-2 text-gray-600">
          Painel médico - Gerencie pacientes e exames laboratoriais
        </p>
      </div>

      {/* Estatísticas */}
      {stats && (
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UsersIcon className="h-8 w-8 text-blue-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total de Pacientes
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalPatients}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ClipboardDocumentListIcon className="h-8 w-8 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total de Exames
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalRequests}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <BeakerIcon className="h-8 w-8 text-yellow-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Pendentes
                  </dt>
                  <dd className="text-lg font-medium text-yellow-900">
                    {stats.pendingRequests}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <DocumentArrowDownIcon className="h-8 w-8 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Concluídos
                  </dt>
                  <dd className="text-lg font-medium text-green-900">
                    {stats.completedRequests}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Ações Rápidas */}
      <div>
        <h2 className="text-lg font-medium text-gray-900 mb-4">Ações Rápidas</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {quickActions.map((action) => (
            <a
              key={action.name}
              href={action.href}
              className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
            >
              <div>
                <span className={`rounded-lg inline-flex p-3 text-white ${action.color}`}>
                  <action.icon className="h-6 w-6" />
                </span>
              </div>
              <div className="mt-4">
                <h3 className="text-lg font-medium text-gray-900">
                  <span className="absolute inset-0" />
                  {action.name}
                </h3>
                <p className="mt-2 text-sm text-gray-500">
                  {action.description}
                </p>
              </div>
            </a>
          ))}
        </div>
      </div>

      {/* Solicitações Recentes */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-medium text-gray-900">Solicitações Recentes</h2>
          <a href="/doctor/exams" className="text-sm text-primary-600 hover:text-primary-700">
            Ver todas
          </a>
        </div>
        
        {recentRequests.length > 0 ? (
          <div className="card">
            <div className="flow-root">
              <ul className="-mb-8">
                {recentRequests.map((request, requestIdx) => (
                  <li key={request.id}>
                    <div className="relative pb-8">
                      {requestIdx !== recentRequests.length - 1 ? (
                        <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200" />
                      ) : null}
                      <div className="relative flex space-x-3">
                        <div>
                          <span className={`h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white ${
                            request.status === 'completed' ? 'bg-green-500' :
                            request.status === 'scheduled' ? 'bg-blue-500' :
                            request.status === 'cancelled' ? 'bg-red-500' : 'bg-gray-500'
                          }`}>
                            <BeakerIcon className="h-5 w-5 text-white" />
                          </span>
                        </div>
                        <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                          <div>
                            <p className="text-sm text-gray-900">
                              <span className="font-medium">{request.patient?.name}</span> - {request.exam_type?.name}
                              <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                request.status === 'completed' ? 'bg-green-100 text-green-800' :
                                request.status === 'scheduled' ? 'bg-blue-100 text-blue-800' :
                                request.status === 'cancelled' ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-800'
                              }`}>
                                {request.status === 'completed' ? 'Concluído' :
                                 request.status === 'scheduled' ? 'Agendado' :
                                 request.status === 'cancelled' ? 'Cancelado' : request.status}
                              </span>
                            </p>
                            {request.result && (
                              <p className="text-sm text-gray-500">
                                Resultado: {request.result.value} {request.result.unit}
                              </p>
                            )}
                          </div>
                          <div className="text-right text-sm whitespace-nowrap text-gray-500">
                            {new Date(request.scheduled_date).toLocaleDateString('pt-BR')}
                          </div>
                        </div>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        ) : (
          <div className="card text-center py-8">
            <ClipboardDocumentListIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Nenhuma solicitação encontrada</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comece criando solicitações de exames para seus pacientes.
            </p>
            <div className="mt-6">
              <a href="/doctor/exams" className="btn-primary">
                Criar Solicitação
              </a>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Placeholder components para outras rotas
const DoctorPatients = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Meus Pacientes</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const DoctorExams = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Solicitações de Exames</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const DoctorResults = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Resultados dos Pacientes</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

export default DoctorDashboard;