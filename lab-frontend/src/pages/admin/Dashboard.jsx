import React, { useState, useEffect } from 'react';
import { Routes, Route } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import api from '../../services/api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  UsersIcon,
  BeakerIcon,
  Cog6ToothIcon,
  ChartBarIcon,
  DocumentTextIcon,
  ServerIcon
} from '@heroicons/react/24/outline';

const AdminDashboard = () => {
  return (
    <Routes>
      <Route path="/" element={<AdminHome />} />
      <Route path="/users" element={<AdminUsers />} />
      <Route path="/exam-types" element={<AdminExamTypes />} />
      <Route path="/system" element={<AdminSystem />} />
    </Routes>
  );
};

const AdminHome = () => {
  const { user } = useAuth();
  const [systemStats, setSystemStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSystemStats();
  }, []);

  const fetchSystemStats = async () => {
    try {
      setLoading(true);
      const response = await api.get('/admin/stats');
      setSystemStats(response.data.system_stats);
    } catch (error) {
      console.error('Erro ao buscar estatísticas do sistema:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const quickActions = [
    {
      name: 'Gerenciar Usuários',
      description: 'Adicionar, editar e remover usuários',
      href: '/admin/users',
      icon: UsersIcon,
      color: 'bg-blue-500 hover:bg-blue-600'
    },
    {
      name: 'Tipos de Exame',
      description: 'Configurar tipos de exames disponíveis',
      href: '/admin/exam-types',
      icon: BeakerIcon,
      color: 'bg-green-500 hover:bg-green-600'
    },
    {
      name: 'Sistema',
      description: 'Monitorar performance e logs',
      href: '/admin/system',
      icon: Cog6ToothIcon,
      color: 'bg-purple-500 hover:bg-purple-600'
    }
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Painel Administrativo
        </h1>
        <p className="mt-2 text-gray-600">
          Bem-vindo, {user?.name}. Gerencie o sistema laboratorial
        </p>
      </div>

      {/* Estatísticas do Sistema */}
      {systemStats && (
        <div className="space-y-6">
          {/* Usuários */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Usuários do Sistema</h3>
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5">
              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <UsersIcon className="h-8 w-8 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Total
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {systemStats.users?.total || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <UsersIcon className="h-8 w-8 text-blue-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Pacientes
                      </dt>
                      <dd className="text-lg font-medium text-blue-900">
                        {systemStats.users?.patients || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <UsersIcon className="h-8 w-8 text-green-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Médicos
                      </dt>
                      <dd className="text-lg font-medium text-green-900">
                        {systemStats.users?.doctors || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <UsersIcon className="h-8 w-8 text-purple-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Lab Techs
                      </dt>
                      <dd className="text-lg font-medium text-purple-900">
                        {systemStats.users?.lab_technicians || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <UsersIcon className="h-8 w-8 text-red-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Admins
                      </dt>
                      <dd className="text-lg font-medium text-red-900">
                        {systemStats.users?.admins || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Exames */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Exames e Resultados</h3>
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <DocumentTextIcon className="h-8 w-8 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Total Requisições
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {systemStats.exam_requests?.total || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <BeakerIcon className="h-8 w-8 text-blue-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Agendados
                      </dt>
                      <dd className="text-lg font-medium text-blue-900">
                        {systemStats.exam_requests?.scheduled || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ChartBarIcon className="h-8 w-8 text-green-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Concluídos
                      </dt>
                      <dd className="text-lg font-medium text-green-900">
                        {systemStats.exam_requests?.completed || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <BeakerIcon className="h-8 w-8 text-purple-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Tipos de Exame
                      </dt>
                      <dd className="text-lg font-medium text-purple-900">
                        {systemStats.exam_types?.total || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Uploads */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Uploads do Laboratório</h3>
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ServerIcon className="h-8 w-8 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Total Uploads
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {systemStats.uploads?.total || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ChartBarIcon className="h-8 w-8 text-green-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Concluídos
                      </dt>
                      <dd className="text-lg font-medium text-green-900">
                        {systemStats.uploads?.completed || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ServerIcon className="h-8 w-8 text-red-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Falharam
                      </dt>
                      <dd className="text-lg font-medium text-red-900">
                        {systemStats.uploads?.failed || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ServerIcon className="h-8 w-8 text-yellow-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Processando
                      </dt>
                      <dd className="text-lg font-medium text-yellow-900">
                        {systemStats.uploads?.processing || 0}
                      </dd>
                    </dl>
                  </div>
                </div>
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

      {/* Exames Mais Solicitados */}
      {systemStats?.exam_types?.most_requested && (
        <div>
          <h2 className="text-lg font-medium text-gray-900 mb-4">Exames Mais Solicitados</h2>
          <div className="card">
            <div className="space-y-3">
              {systemStats.exam_types.most_requested.map((exam, index) => (
                <div key={index} className="flex justify-between items-center">
                  <span className="text-sm font-medium text-gray-900">{exam.name}</span>
                  <span className="text-sm text-gray-500">{exam.count} solicitações</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// Placeholder components para outras rotas
const AdminUsers = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Gerenciar Usuários</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const AdminExamTypes = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Tipos de Exame</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

const AdminSystem = () => (
  <div className="text-center py-8">
    <h1 className="text-2xl font-bold text-gray-900 mb-4">Sistema</h1>
    <p className="text-gray-600">Página em desenvolvimento...</p>
  </div>
);

export default AdminDashboard;