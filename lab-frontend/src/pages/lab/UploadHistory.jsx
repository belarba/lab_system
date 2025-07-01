import React, { useState, useEffect } from 'react';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { format } from 'date-fns';
import {
  FolderIcon,
  DocumentTextIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
  EyeIcon,
  ArrowPathIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';

const UploadHistory = () => {
  const { request } = useApi();
  
  const [uploads, setUploads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedUpload, setSelectedUpload] = useState(null);
  const [showDetails, setShowDetails] = useState(false);
  const [filters, setFilters] = useState({
    status: '',
    dateFrom: '',
    dateTo: ''
  });

  useEffect(() => {
    fetchUploads();
  }, []);

  const fetchUploads = async () => {
    try {
      setLoading(true);
      let url = '/uploads?limit=50';
      
      // Aplicar filtros se existirem
      const params = new URLSearchParams();
      if (filters.status) params.append('status', filters.status);
      if (filters.dateFrom) params.append('from_date', filters.dateFrom);
      if (filters.dateTo) params.append('to_date', filters.dateTo);
      
      if (params.toString()) {
        url += '&' + params.toString();
      }

      const response = await request({ method: 'GET', url });
      if (response.data) {
        setUploads(response.data.uploads || []);
      }
    } catch (error) {
      console.error('Erro ao buscar uploads:', error);
    } finally {
      setLoading(false);
    }
  };

  const viewUploadDetails = async (upload) => {
    try {
      const response = await request({ 
        method: 'GET', 
        url: `/uploads/${upload.id}` 
      });
      
      if (response.data) {
        setSelectedUpload(response.data.upload);
        setShowDetails(true);
      }
    } catch (error) {
      console.error('Erro ao buscar detalhes do upload:', error);
      alert('Erro ao carregar detalhes do upload');
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircleIcon className="h-5 w-5 text-green-500" />;
      case 'failed':
        return <XCircleIcon className="h-5 w-5 text-red-500" />;
      case 'processing':
        return <ClockIcon className="h-5 w-5 text-yellow-500" />;
      default:
        return <ClockIcon className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'completed':
        return 'Concluído';
      case 'failed':
        return 'Falhou';
      case 'processing':
        return 'Processando';
      case 'pending':
        return 'Pendente';
      default:
        return status;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'failed':
        return 'bg-red-100 text-red-800';
      case 'processing':
        return 'bg-yellow-100 text-yellow-800';
      case 'pending':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const applyFilters = () => {
    fetchUploads();
  };

  const clearFilters = () => {
    setFilters({
      status: '',
      dateFrom: '',
      dateTo: ''
    });
    setTimeout(() => {
      fetchUploads();
    }, 100);
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Histórico de Uploads</h1>
        <p className="mt-2 text-gray-600">
          Visualize e gerencie todos os arquivos enviados
        </p>
      </div>

      {/* Filtros */}
      <div className="card">
        <div className="flex items-center mb-4">
          <ChartBarIcon className="h-6 w-6 text-gray-600 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Filtros</h3>
        </div>
        
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Status
            </label>
            <select
              value={filters.status}
              onChange={(e) => setFilters({...filters, status: e.target.value})}
              className="input-field"
            >
              <option value="">Todos</option>
              <option value="completed">Concluído</option>
              <option value="failed">Falhou</option>
              <option value="processing">Processando</option>
              <option value="pending">Pendente</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data Inicial
            </label>
            <input
              type="date"
              value={filters.dateFrom}
              onChange={(e) => setFilters({...filters, dateFrom: e.target.value})}
              className="input-field"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data Final
            </label>
            <input
              type="date"
              value={filters.dateTo}
              onChange={(e) => setFilters({...filters, dateTo: e.target.value})}
              className="input-field"
            />
          </div>

          <div className="flex items-end space-x-2">
            <button
              onClick={applyFilters}
              className="btn-primary"
            >
              Aplicar
            </button>
            <button
              onClick={clearFilters}
              className="btn-secondary"
            >
              Limpar
            </button>
          </div>
        </div>
      </div>

      {/* Lista de Uploads */}
      <div className="card">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center">
            <FolderIcon className="h-8 w-8 text-primary-600 mr-3" />
            <h2 className="text-xl font-semibold text-gray-900">
              Arquivos Enviados ({uploads.length})
            </h2>
          </div>
          <button
            onClick={fetchUploads}
            className="btn-secondary flex items-center"
          >
            <ArrowPathIcon className="h-4 w-4 mr-2" />
            Atualizar
          </button>
        </div>

        {uploads.length > 0 ? (
          <div className="overflow-hidden">
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
                    Data Upload
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ações
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {uploads.map((upload) => (
                  <tr key={upload.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <DocumentTextIcon className="h-5 w-5 text-gray-400 mr-2" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {upload.filename}
                          </div>
                          <div className="text-sm text-gray-500">
                            {formatFileSize(upload.file_size)}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {getStatusIcon(upload.status)}
                        <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(upload.status)}`}>
                          {getStatusText(upload.status)}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <div>
                        {upload.processed_records || 0} / {upload.total_records || 0}
                      </div>
                      {upload.failed_records > 0 && (
                        <div className="text-xs text-red-600">
                          {upload.failed_records} falhas
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {upload.success_rate !== null ? (
                        <div className="flex items-center">
                          <div className="w-16 bg-gray-200 rounded-full h-2 mr-2">
                            <div 
                              className={`h-2 rounded-full ${
                                upload.success_rate >= 80 ? 'bg-green-600' :
                                upload.success_rate >= 50 ? 'bg-yellow-600' :
                                'bg-red-600'
                              }`}
                              style={{ width: `${upload.success_rate}%` }}
                            ></div>
                          </div>
                          <span className="text-sm text-gray-900">
                            {upload.success_rate}%
                          </span>
                        </div>
                      ) : (
                        <span className="text-sm text-gray-500">-</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <div>
                        {format(new Date(upload.created_at), 'dd/MM/yyyy')}
                      </div>
                      <div>
                        {format(new Date(upload.created_at), 'HH:mm')}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => viewUploadDetails(upload)}
                        className="text-primary-600 hover:text-primary-900 flex items-center"
                      >
                        <EyeIcon className="h-4 w-4 mr-1" />
                        Ver Detalhes
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8">
            <FolderIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Nenhum upload encontrado</h3>
            <p className="mt-1 text-sm text-gray-500">
              {Object.values(filters).some(f => f) 
                ? 'Tente ajustar os filtros ou fazer um novo upload.'
                : 'Comece fazendo upload de arquivos com resultados laboratoriais.'
              }
            </p>
            <div className="mt-6">
              <a href="/lab/upload" className="btn-primary">
                Fazer Upload
              </a>
            </div>
          </div>
        )}
      </div>

      {/* Modal de Detalhes */}
      {showDetails && selectedUpload && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 max-w-4xl shadow-lg rounded-md bg-white">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl font-bold text-gray-900">
                Detalhes do Upload: {selectedUpload.filename}
              </h2>
              <button
                onClick={() => setShowDetails(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ×
              </button>
            </div>

            <div className="space-y-6">
              {/* Informações Gerais */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <div className="text-lg font-semibold text-blue-900">
                    {selectedUpload.total_records || 0}
                  </div>
                  <div className="text-sm text-blue-700">Total de Registros</div>
                </div>
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="text-lg font-semibold text-green-900">
                    {selectedUpload.processed_records || 0}
                  </div>
                  <div className="text-sm text-green-700">Processados</div>
                </div>
                <div className="bg-red-50 p-4 rounded-lg">
                  <div className="text-lg font-semibold text-red-900">
                    {selectedUpload.failed_records || 0}
                  </div>
                  <div className="text-sm text-red-700">Falharam</div>
                </div>
              </div>

              {/* Status e Datas */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="text-lg font-medium text-gray-900 mb-3">Informações do Processamento</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <span className="text-sm font-medium text-gray-500">Status:</span>
                    <div className="flex items-center mt-1">
                      {getStatusIcon(selectedUpload.status)}
                      <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(selectedUpload.status)}`}>
                        {getStatusText(selectedUpload.status)}
                      </span>
                    </div>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500">Taxa de Sucesso:</span>
                    <div className="mt-1 text-sm text-gray-900">
                      {selectedUpload.success_rate}%
                    </div>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500">Data de Upload:</span>
                    <div className="mt-1 text-sm text-gray-900">
                      {format(new Date(selectedUpload.created_at), 'dd/MM/yyyy HH:mm')}
                    </div>
                  </div>
                  {selectedUpload.processed_at && (
                    <div>
                      <span className="text-sm font-medium text-gray-500">Processado em:</span>
                      <div className="mt-1 text-sm text-gray-900">
                        {format(new Date(selectedUpload.processed_at), 'dd/MM/yyyy HH:mm')}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Detalhes do Processamento */}
              {selectedUpload.processing_summary && (
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-3">Detalhes do Processamento</h3>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="space-y-2">
                      {selectedUpload.processing_summary.details && 
                       selectedUpload.processing_summary.details.map((detail, index) => (
                        <div key={index} className="flex justify-between items-start text-sm">
                          <span className="text-gray-600">
                            {new Date(detail.timestamp).toLocaleTimeString('pt-BR')}
                          </span>
                          <span className="text-gray-900 ml-4 flex-1">
                            {detail.message}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* Erros */}
              {selectedUpload.error_details && (
                <div>
                  <h3 className="text-lg font-medium text-red-900 mb-3">Detalhes dos Erros</h3>
                  <div className="bg-red-50 border border-red-200 p-4 rounded-lg">
                    <div className="text-sm text-red-800">
                      {selectedUpload.error_details}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Botões */}
            <div className="mt-6 flex justify-end space-x-3">
              <button
                onClick={() => setShowDetails(false)}
                className="btn-secondary"
              >
                Fechar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UploadHistory;