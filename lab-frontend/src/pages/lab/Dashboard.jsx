import React, { useState, useEffect } from 'react';
import { Routes, Route, Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import api from '../../services/api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import UploadResults from './UploadResults';
import UploadHistory from './UploadHistory';
import {
  DocumentArrowUpIcon,
  FolderIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon
} from '@heroicons/react/24/outline';

const LabDashboard = () => {
  return (
    <Routes>
      <Route path="/" element={<LabHome />} />
      <Route path="/upload" element={<UploadResults />} />
      <Route path="/uploads" element={<UploadHistory />} />
    </Routes>
  );
};

const LabHome = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [recentUploads, setRecentUploads] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      
      // Buscar uploads recentes
      const uploadsResponse = await api.get('/uploads?limit=5');
      const uploads = uploadsResponse.data.uploads || [];
      setRecentUploads(uploads);
      
      // Buscar todos os uploads para estatísticas
      const allUploadsResponse = await api.get('/uploads');
      const allUploads = allUploadsResponse.data.uploads || [];
      
      setStats({
        totalUploads: allUploads.length,
        completedUploads: allUploads.filter(upload => upload.status === 'completed').length,
        failedUploads: allUploads.filter(upload => upload.status === 'failed').length,
        processingUploads: allUploads.filter(upload => upload.status === 'processing').length,
        totalRecordsProcessed: allUploads.reduce((sum, upload) => sum + (upload.processed_records || 0), 0),
      });
      
    } catch (error) {
      console.error('Erro ao buscar dados do dashboard:', error);
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
      name: 'Upload Resultados',
      description: 'Faça upload de arquivos CSV com resultados',
      to: '/lab/upload',
      icon: DocumentArrowUpIcon,
      color: 'bg-blue-500 hover:bg-blue-600'
    },
    {
      name: 'Histórico Uploads',
      description: 'Visualize todos os uploads realizados',
      to: '/lab/uploads',
      icon: FolderIcon,
      color: 'bg-green-500 hover:bg-green-600'
    }
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          {user?.name} - Laboratório
        </h1>
        <p className="mt-2 text-gray-600">
          Gerencie uploads de resultados laboratoriais
        </p>
      </div>

      {/* Estatísticas */}
      {stats && (
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5">
          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <FolderIcon className="h-8 w-8 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Uploads
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalUploads}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <CheckCircleIcon className="h-8 w-8 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Concluídos
                  </dt>
                  <dd className="text-lg font-medium text-green-900">
                    {stats.completedUploads}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <XCircleIcon className="h-8 w-8 text-red-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Falharam
                  </dt>
                  <dd className="text-lg font-medium text-red-900">
                    {stats.failedUploads}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ClockIcon className="h-8 w-8 text-yellow-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Processando
                  </dt>
                  <dd className="text-lg font-medium text-yellow-900">
                    {stats.processingUploads}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <DocumentArrowUpIcon className="h-8 w-8 text-blue-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Registros
                  </dt>
                  <dd className="text-lg font-medium text-blue-900">
                    {stats.totalRecordsProcessed}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Ações Rápidas - CORRIGIDO: usando Link ao invés de href */}
      <div>
        <h2 className="text-lg font-medium text-gray-900 mb-4">Ações Rápidas</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {quickActions.map((action) => (
            <Link
              key={action.name}
              to={action.to}
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
            </Link>
          ))}
        </div>
      </div>

      {/* Uploads Recentes */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-medium text-gray-900">Uploads Recentes</h2>
          <Link to="/lab/uploads" className="text-sm text-primary-600 hover:text-primary-700">
            Ver todos
          </Link>
        </div>
        
        {recentUploads.length > 0 ? (
          <div className="card overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Arquivo
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Registros
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Taxa Sucesso
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Data
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {recentUploads.map((upload) => (
                  <tr key={upload.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {upload.filename}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        upload.status === 'completed' ? 'bg-green-100 text-green-800' :
                        upload.status === 'failed' ? 'bg-red-100 text-red-800' :
                        upload.status === 'processing' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {upload.status === 'completed' ? 'Concluído' :
                         upload.status === 'failed' ? 'Falhou' :
                         upload.status === 'processing' ? 'Processando' :
                         upload.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {upload.processed_records || 0} / {upload.total_records || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {upload.success_rate ? `${upload.success_rate}%` : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(upload.created_at).toLocaleDateString('pt-BR')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="card text-center py-8">
            <DocumentArrowUpIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Nenhum upload encontrado</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comece fazendo upload de arquivos com resultados laboratoriais.
            </p>
            <div className="mt-6">
              <Link to="/lab/upload" className="btn-primary">
                Fazer Upload
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default LabDashboard;