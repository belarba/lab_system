import React, { useState, useEffect, useCallback } from 'react';
import { Routes, Route } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import api from '../../services/api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  ClipboardDocumentListIcon,
  BeakerIcon,
  DocumentTextIcon,
  CalendarIcon
} from '@heroicons/react/24/outline';

const PatientDashboard = () => {
  return (
    <Routes>
      <Route path="/" element={<PatientHome />} />
      <Route path="/exams" element={<PatientExams />} />
      <Route path="/request" element={<RequestExam />} />
      <Route path="/results" element={<PatientResults />} />
    </Routes>
  );
};

const PatientHome = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [recentExams, setRecentExams] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchDashboardData = useCallback(async () => {
    try {
      setLoading(true);
      
      // Buscar exames recentes
      const examsResponse = await api.get(`/patients/${user.id}/blood_work_requests?limit=5`);
      setRecentExams(examsResponse.data.blood_work_requests || []);
      
      // Calcular estatísticas simples
      const allExamsResponse = await api.get(`/patients/${user.id}/blood_work_requests`);
      const allExams = allExamsResponse.data.blood_work_requests || [];
      
      setStats({
        totalExams: allExams.length,
        pendingExams: allExams.filter(exam => exam.status === 'scheduled').length,
        completedExams: allExams.filter(exam => exam.status === 'completed').length,
        cancelledExams: allExams.filter(exam => exam.status === 'cancelled').length,
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
      name: 'Solicitar Exame',
      description: 'Solicite um novo exame laboratorial',
      href: '/patient/request',
      icon: BeakerIcon,
      color: 'bg-blue-500 hover:bg-blue-600'
    },
    {
      name: 'Ver Resultados',
      description: 'Visualize seus resultados de exames',
      href: '/patient/results',
      icon: DocumentTextIcon,
      color: 'bg-green-500 hover:bg-green-600'
    },
    {
      name: 'Meus Exames',
      description: 'Acompanhe seus exames agendados',
      href: '/patient/exams',
      icon: ClipboardDocumentListIcon,
      color: 'bg-purple-500 hover:bg-purple-600'
    }
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Bem-vindo, {user?.name}!
        </h1>
        <p className="mt-2 text-gray-600">
          Acompanhe seus exames e resultados laboratoriais
        </p>
      </div>

      {/* Estatísticas */}
      {stats && (
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
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
                    {stats.totalExams}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <CalendarIcon className="h-8 w-8 text-blue-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Agendados
                  </dt>
                  <dd className="text-lg font-medium text-blue-900">
                    {stats.pendingExams}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <DocumentTextIcon className="h-8 w-8 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Concluídos
                  </dt>
                  <dd className="text-lg font-medium text-green-900">
                    {stats.completedExams}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <BeakerIcon className="h-8 w-8 text-red-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Cancelados
                  </dt>
                  <dd className="text-lg font-medium text-red-900">
                    {stats.cancelledExams}
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

      {/* Exames Recentes */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-medium text-gray-900">Exames Recentes</h2>
          <a href="/patient/exams" className="text-sm text-primary-600 hover:text-primary-700">
            Ver todos
          </a>
        </div>
        
        {recentExams.length > 0 ? (
          <div className="card">
            <div className="flow-root">
              <ul className="-mb-8">
                {recentExams.map((exam, examIdx) => (
                  <li key={exam.id}>
                    <div className="relative pb-8">
                      {examIdx !== recentExams.length - 1 ? (
                        <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200" />
                      ) : null}
                      <div className="relative flex space-x-3">
                        <div>
                          <span className={`h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white ${
                            exam.status === 'completed' ? 'bg-green-500' :
                            exam.status === 'scheduled' ? 'bg-blue-500' :
                            exam.status === 'cancelled' ? 'bg-red-500' : 'bg-gray-500'
                          }`}>
                            <BeakerIcon className="h-5 w-5 text-white" />
                          </span>
                        </div>
                        <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                          <div>
                            <p className="text-sm text-gray-900">
                              {exam.exam_type?.name} - 
                              <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                exam.status === 'completed' ? 'bg-green-100 text-green-800' :
                                exam.status === 'scheduled' ? 'bg-blue-100 text-blue-800' :
                                exam.status === 'cancelled' ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-800'
                              }`}>
                                {exam.status === 'completed' ? 'Concluído' :
                                 exam.status === 'scheduled' ? 'Agendado' :
                                 exam.status === 'cancelled' ? 'Cancelado' : exam.status}
                              </span>
                            </p>
                            <p className="text-sm text-gray-500">
                              Dr. {exam.doctor?.name}
                            </p>
                          </div>
                          <div className="text-right text-sm whitespace-nowrap text-gray-500">
                            {new Date(exam.scheduled_date).toLocaleDateString('pt-BR')}
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
            <BeakerIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Nenhum exame encontrado</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comece solicitando seu primeiro exame laboratorial.
            </p>
            <div className="mt-6">
              <a href="/patient/request" className="btn-primary">
                Solicitar Exame
              </a>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Placeholder components para outras rotas
const PatientExams = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Meus Exames</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const RequestExam = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Solicitar Exame</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const PatientResults = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Meus Resultados</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

export default PatientDashboard;