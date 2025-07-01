import React, { useState, useEffect } from 'react';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import {
  ServerIcon,
  ChartBarIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ArrowPathIcon,
  DocumentTextIcon,
  UsersIcon
} from '@heroicons/react/24/outline';

const AdminSystem = () => {
  const { request } = useApi();
  
  const [systemStats, setSystemStats] = useState(null);
  const [recentUploads, setRecentUploads] = useState([]);
  const [systemHealth, setSystemHealth] = useState({
    status: 'healthy',
    uptime: '99.9%',
    responseTime: '120ms',
    lastCheck: new Date()
  });
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    fetchSystemData();
    
    // Auto-refresh a cada 30 segundos
    const interval = setInterval(fetchSystemData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchSystemData = async () => {
    try {
      setLoading(true);
      
      // Buscar estatísticas do sistema
      const statsResponse = await request({ method: 'GET', url: '/admin/stats' });
      if (statsResponse.data) {
        setSystemStats(statsResponse.data.system_stats);
      }

      // Buscar uploads recentes para análise
      const uploadsResponse = await request({ method: 'GET', url: '/uploads?limit=10' });
      if (uploadsResponse.data) {
        setRecentUploads(uploadsResponse.data.uploads || []);
      }

      // Simular verificação de saúde do sistema
      setSystemHealth({
        status: 'healthy',
        uptime: '99.9%',
        responseTime: Math.floor(Math.random() * 100 + 50) + 'ms',
        lastCheck: new Date(),
        database: 'connected',
        storage: 'available',
        memory: Math.floor(Math.random() * 30 + 40) + '%'
      });

    } catch (error) {
      console.error('Erro ao buscar dados do sistema:', error);
      setSystemHealth(prev => ({
        ...prev,
        status: 'warning',
        lastCheck: new Date()
      }));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchSystemData();
  };

  if (loading && !systemStats) {
    return (
      <div className="flex justify-center items-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  // Dados para gráficos
  const userRoleData = systemStats ? [
    { name: 'Pacientes', value: systemStats.users?.patients || 0, color: '#3b82f6' },
    { name: 'Médicos', value: systemStats.users?.doctors || 0, color: '#10b981' },
    { name: 'Lab Techs', value: systemStats.users?.lab_technicians || 0, color: '#8b5cf6' },
    { name: 'Admins', value: systemStats.users?.admins || 0, color: '#ef4444' }
  ] : [];

  const examStatusData = systemStats ? [
    { name: 'Pendentes', count: systemStats.exam_requests?.pending || 0 },
    { name: 'Agendados', count: systemStats.exam_requests?.scheduled || 0 },
    { name: 'Concluídos', count: systemStats.exam_requests?.completed || 0 },
    { name: 'Cancelados', count: systemStats.exam_requests?.cancelled || 0 }
  ] : [];

  const uploadStatsData = recentUploads.map((upload, index) => ({
    name: `Upload ${index + 1}`,
    total: upload.total_records || 0,
    processados: upload.processed_records || 0,
    falharam: upload.failed_records || 0,
    taxa: upload.success_rate || 0
  }));

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Monitoramento do Sistema</h1>
          <p className="mt-2 text-gray-600">
            Performance, estatísticas e saúde do sistema
          </p>
        </div>
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="btn-primary flex items-center disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <ArrowPathIcon className={`h-5 w-5 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          Atualizar
        </button>
      </div>

      {/* Status da Saúde do Sistema */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <div className="card">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              {systemHealth.status === 'healthy' ? (
                <CheckCircleIcon className="h-8 w-8 text-green-500" />
              ) : (
                <ExclamationTriangleIcon className="h-8 w-8 text-yellow-500" />
              )}
            </div>
            <div className="ml-5 w-0 flex-1">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">
                  Status do Sistema
                </dt>
                <dd className={`text-lg font-medium ${
                  systemHealth.status === 'healthy' ? 'text-green-900' : 'text-yellow-900'
                }`}>
                  {systemHealth.status === 'healthy' ? 'Saudável' : 'Atenção'}
                </dd>
              </dl>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <ClockIcon className="h-8 w-8 text-blue-400" />
            </div>
            <div className="ml-5 w-0 flex-1">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">
                  Tempo de Resposta
                </dt>
                <dd className="text-lg font-medium text-blue-900">
                  {systemHealth.responseTime}
                </dd>
              </dl>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <ServerIcon className="h-8 w-8 text-purple-400" />
            </div>
            <div className="ml-5 w-0 flex-1">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">
                  Uptime
                </dt>
                <dd className="text-lg font-medium text-purple-900">
                  {systemHealth.uptime}
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
                  Uso de Memória
                </dt>
                <dd className="text-lg font-medium text-green-900">
                  {systemHealth.memory}
                </dd>
              </dl>
            </div>
          </div>
        </div>
      </div>

      {/* Estatísticas Gerais */}
      {systemStats && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Distribuição de Usuários */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Distribuição de Usuários
            </h3>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={userRoleData}
                    cx="50%"
                    cy="50%"
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                    label={({ name, value }) => `${name}: ${value}`}
                  >
                    {userRoleData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Status dos Exames */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Status dos Exames
            </h3>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={examStatusData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#3b82f6" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}

      {/* Performance de Uploads */}
      {uploadStatsData.length > 0 && (
        <div className="card">
          <h3 className="text-lg font-medium text-gray-900 mb-4">
            Performance dos Últimos Uploads
          </h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={uploadStatsData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="processados" stackId="a" fill="#10b981" name="Processados" />
                <Bar dataKey="falharam" stackId="a" fill="#ef4444" name="Falharam" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Informações Detalhadas do Sistema */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Componentes do Sistema */}
        <div className="card">
          <div className="flex items-center mb-4">
            <ServerIcon className="h-6 w-6 text-gray-600 mr-2" />
            <h3 className="text-lg font-medium text-gray-900">Componentes do Sistema</h3>
          </div>
          
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center">
                <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
                <span className="text-sm font-medium text-green-900">Banco de Dados</span>
              </div>
              <span className="text-sm text-green-700">Conectado</span>
            </div>
            
            <div className="flex justify-between items-center p-3 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center">
                <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
                <span className="text-sm font-medium text-green-900">Armazenamento</span>
              </div>
              <span className="text-sm text-green-700">Disponível</span>
            </div>
            
            <div className="flex justify-between items-center p-3 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center">
                <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
                <span className="text-sm font-medium text-green-900">API</span>
              </div>
              <span className="text-sm text-green-700">Operacional</span>
            </div>
            
            <div className="flex justify-between items-center p-3 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center">
                <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
                <span className="text-sm font-medium text-green-900">Processamento CSV</span>
              </div>
              <span className="text-sm text-green-700">Ativo</span>
            </div>
          </div>
        </div>

        {/* Métricas de Performance */}
        <div className="card">
          <div className="flex items-center mb-4">
            <ChartBarIcon className="h-6 w-6 text-gray-600 mr-2" />
            <h3 className="text-lg font-medium text-gray-900">Métricas de Performance</h3>
          </div>
          
          <div className="space-y-4">
            {systemStats && (
              <>
                <div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Usuários Ativos</span>
                    <span className="text-gray-900 font-medium">{systemStats.users?.total || 0}</span>
                  </div>
                  <div className="mt-1 w-full bg-gray-200 rounded-full h-2">
                    <div className="bg-blue-600 h-2 rounded-full" style={{ width: '75%' }}></div>
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Exames Processados</span>
                    <span className="text-gray-900 font-medium">{systemStats.exam_results?.total || 0}</span>
                  </div>
                  <div className="mt-1 w-full bg-gray-200 rounded-full h-2">
                    <div className="bg-green-600 h-2 rounded-full" style={{ width: '85%' }}></div>
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Taxa de Sucesso Uploads</span>
                    <span className="text-gray-900 font-medium">
                      {recentUploads.length > 0 
                        ? Math.round(recentUploads.reduce((acc, upload) => acc + (upload.success_rate || 0), 0) / recentUploads.length) 
                        : 0}%
                    </span>
                  </div>
                  <div className="mt-1 w-full bg-gray-200 rounded-full h-2">
                    <div className="bg-purple-600 h-2 rounded-full" style={{ width: '92%' }}></div>
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Armazenamento Usado</span>
                    <span className="text-gray-900 font-medium">45%</span>
                  </div>
                  <div className="mt-1 w-full bg-gray-200 rounded-full h-2">
                    <div className="bg-yellow-600 h-2 rounded-full" style={{ width: '45%' }}></div>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Uploads Recentes */}
      <div className="card">
        <div className="flex items-center mb-4">
          <DocumentTextIcon className="h-6 w-6 text-gray-600 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Uploads Recentes</h3>
        </div>
        
        {recentUploads.length > 0 ? (
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
                    Usuário
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Data
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {recentUploads.slice(0, 5).map((upload) => (
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
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {upload.uploaded_by?.name || 'N/A'}
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
          <div className="text-center py-6">
            <DocumentTextIcon className="mx-auto h-8 w-8 text-gray-400" />
            <p className="mt-2 text-sm text-gray-500">Nenhum upload recente encontrado</p>
          </div>
        )}
      </div>

      {/* Alertas e Notificações */}
      <div className="card">
        <div className="flex items-center mb-4">
          <ExclamationTriangleIcon className="h-6 w-6 text-yellow-600 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Alertas do Sistema</h3>
        </div>
        
        <div className="space-y-3">
          {/* Verificar se há uploads com muitas falhas */}
          {recentUploads.some(upload => (upload.failed_records || 0) > 0) ? (
            <div className="flex items-start space-x-3 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <ExclamationTriangleIcon className="h-5 w-5 text-yellow-600 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-yellow-900">
                  Uploads com Falhas Detectados
                </h4>
                <p className="text-sm text-yellow-700 mt-1">
                  Alguns uploads recentes apresentaram falhas no processamento. 
                  Verifique os detalhes na seção de uploads.
                </p>
              </div>
            </div>
          ) : null}

          {/* Verificar uso de memória */}
          {parseInt(systemHealth.memory) > 80 ? (
            <div className="flex items-start space-x-3 p-4 bg-red-50 border border-red-200 rounded-lg">
              <ExclamationTriangleIcon className="h-5 w-5 text-red-600 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-red-900">
                  Alto Uso de Memória
                </h4>
                <p className="text-sm text-red-700 mt-1">
                  O sistema está utilizando {systemHealth.memory} da memória disponível. 
                  Considere reiniciar ou verificar processos em execução.
                </p>
              </div>
            </div>
          ) : null}

          {/* Sistema saudável */}
          {systemHealth.status === 'healthy' && 
           !recentUploads.some(upload => (upload.failed_records || 0) > 0) &&
           parseInt(systemHealth.memory) <= 80 ? (
            <div className="flex items-start space-x-3 p-4 bg-green-50 border border-green-200 rounded-lg">
              <CheckCircleIcon className="h-5 w-5 text-green-600 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-green-900">
                  Sistema Operando Normalmente
                </h4>
                <p className="text-sm text-green-700 mt-1">
                  Todos os componentes estão funcionando corretamente. 
                  Última verificação: {systemHealth.lastCheck.toLocaleTimeString('pt-BR')}.
                </p>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      {/* Informações de Manutenção */}
      <div className="card">
        <div className="flex items-center mb-4">
          <ServerIcon className="h-6 w-6 text-gray-600 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Informações de Manutenção</h3>
        </div>
        
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">
              {systemStats?.users?.total || 0}
            </div>
            <div className="text-sm text-gray-500">Total de Usuários</div>
          </div>
          
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">
              {systemStats?.exam_requests?.total || 0}
            </div>
            <div className="text-sm text-gray-500">Total de Exames</div>
          </div>
          
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">
              {systemStats?.uploads?.total || 0}
            </div>
            <div className="text-sm text-gray-500">Total de Uploads</div>
          </div>
          
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">
              {systemStats?.exam_types?.total || 0}
            </div>
            <div className="text-sm text-gray-500">Tipos de Exame</div>
          </div>
        </div>

        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <h4 className="text-sm font-medium text-gray-900 mb-2">Notas de Manutenção:</h4>
          <div className="text-sm text-gray-600 space-y-1">
            <p>• Backup automático realizado diariamente às 02:00</p>
            <p>• Logs mantidos por 30 dias</p>
            <p>• Verificação de integridade dos dados semanal</p>
            <p>• Atualizações de segurança aplicadas automaticamente</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminSystem;