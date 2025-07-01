import React, { useState, useEffect } from 'react';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  BeakerIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  XMarkIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon
} from '@heroicons/react/24/outline';

const AdminExamTypes = () => {
  const { request } = useApi();
  
  const [examTypes, setExamTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedExamType, setSelectedExamType] = useState(null);

  useEffect(() => {
    fetchExamTypes();
  }, []);

  const fetchExamTypes = async () => {
    try {
      setLoading(true);
      const response = await request({ method: 'GET', url: '/admin/exam_types' });
      if (response.data) {
        setExamTypes(response.data.exam_types || []);
      }
    } catch (error) {
      console.error('Erro ao buscar tipos de exame:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateExamType = async (examTypeData) => {
    try {
      const response = await request({
        method: 'POST',
        url: '/admin/exam_types',
        data: { exam_type: examTypeData }
      });

      if (response.data && !response.error) {
        await fetchExamTypes();
        setShowCreateModal(false);
        alert('Tipo de exame criado com sucesso!');
      } else {
        alert(`Erro ao criar tipo de exame: ${response.error}`);
      }
    } catch (error) {
      console.error('Erro ao criar tipo de exame:', error);
      alert('Erro ao criar tipo de exame');
    }
  };

  const handleUpdateExamType = async (examTypeData) => {
    try {
      const response = await request({
        method: 'PUT',
        url: `/admin/exam_types/${selectedExamType.id}`,
        data: { exam_type: examTypeData }
      });

      if (response.data && !response.error) {
        await fetchExamTypes();
        setShowEditModal(false);
        setSelectedExamType(null);
        alert('Tipo de exame atualizado com sucesso!');
      } else {
        alert(`Erro ao atualizar tipo de exame: ${response.error}`);
      }
    } catch (error) {
      console.error('Erro ao atualizar tipo de exame:', error);
      alert('Erro ao atualizar tipo de exame');
    }
  };

  const handleDeleteExamType = async () => {
    try {
      const response = await request({
        method: 'DELETE',
        url: `/admin/exam_types/${selectedExamType.id}`
      });

      if (response.data && !response.error) {
        await fetchExamTypes();
        setShowDeleteModal(false);
        setSelectedExamType(null);
        alert('Tipo de exame excluído com sucesso!');
      } else {
        alert(`Erro ao excluir tipo de exame: ${response.error}`);
      }
    } catch (error) {
      console.error('Erro ao excluir tipo de exame:', error);
      alert('Erro ao excluir tipo de exame');
    }
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
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Tipos de Exame</h1>
          <p className="mt-2 text-gray-600">
            Configure os tipos de exames disponíveis no sistema
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="btn-primary flex items-center"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Novo Tipo de Exame
        </button>
      </div>

      {/* Lista de Tipos de Exame */}
      <div className="card">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center">
            <BeakerIcon className="h-8 w-8 text-primary-600 mr-3" />
            <h2 className="text-xl font-semibold text-gray-900">
              Tipos de Exame ({examTypes.length})
            </h2>
          </div>
        </div>

        {examTypes.length > 0 ? (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {examTypes.map((examType) => (
              <div key={examType.id} className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-medium text-gray-900">
                      {examType.name}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {examType.description}
                    </p>
                  </div>
                  <div className="flex space-x-2 ml-4">
                    <button
                      onClick={() => {
                        setSelectedExamType(examType);
                        setShowEditModal(true);
                      }}
                      className="text-primary-600 hover:text-primary-900"
                    >
                      <PencilIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => {
                        setSelectedExamType(examType);
                        setShowDeleteModal(true);
                      }}
                      className="text-red-600 hover:text-red-900"
                    >
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Unidade:</span>
                    <span className="text-gray-900 font-medium">{examType.unit}</span>
                  </div>
                  
                  {examType.reference_range && (
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-500">Faixa de Referência:</span>
                      <span className="text-gray-900 font-medium">{examType.reference_range}</span>
                    </div>
                  )}
                  
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Solicitações:</span>
                    <span className="text-gray-900 font-medium">{examType.requests_count || 0}</span>
                  </div>
                  
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Criado em:</span>
                    <span className="text-gray-900">
                      {new Date(examType.created_at).toLocaleDateString('pt-BR')}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8">
            <BeakerIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Nenhum tipo de exame encontrado</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comece criando o primeiro tipo de exame.
            </p>
            <div className="mt-6">
              <button
                onClick={() => setShowCreateModal(true)}
                className="btn-primary"
              >
                Criar Primeiro Tipo
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Modal Criar Tipo de Exame */}
      {showCreateModal && (
        <ExamTypeFormModal
          title="Criar Novo Tipo de Exame"
          onSubmit={handleCreateExamType}
          onClose={() => setShowCreateModal(false)}
        />
      )}

      {/* Modal Editar Tipo de Exame */}
      {showEditModal && selectedExamType && (
        <ExamTypeFormModal
          title="Editar Tipo de Exame"
          examType={selectedExamType}
          onSubmit={handleUpdateExamType}
          onClose={() => {
            setShowEditModal(false);
            setSelectedExamType(null);
          }}
        />
      )}

      {/* Modal Confirmar Exclusão */}
      {showDeleteModal && selectedExamType && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3 text-center">
              <ExclamationTriangleIcon className="mx-auto h-16 w-16 text-red-500" />
              <h3 className="text-lg font-medium text-gray-900 mt-4">
                Confirmar Exclusão
              </h3>
              <div className="mt-2 px-7 py-3">
                <p className="text-sm text-gray-500">
                  Tem certeza que deseja excluir o tipo de exame <strong>{selectedExamType.name}</strong>?
                </p>
                {selectedExamType.requests_count > 0 && (
                  <p className="text-sm text-red-600 mt-2">
                    Atenção: Este tipo de exame possui {selectedExamType.requests_count} solicitações associadas.
                  </p>
                )}
              </div>
              <div className="flex justify-center space-x-3 mt-4">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedExamType(null);
                  }}
                  className="btn-secondary"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleDeleteExamType}
                  className="bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-md"
                >
                  Excluir
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Informações Adicionais */}
      <div className="card">
        <div className="flex items-center mb-4">
          <DocumentTextIcon className="h-6 w-6 text-gray-600 mr-2" />
          <h3 className="text-lg font-medium text-gray-900">Informações sobre Tipos de Exame</h3>
        </div>
        
        <div className="space-y-4 text-sm text-gray-600">
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Campos Obrigatórios:</h4>
            <ul className="list-disc list-inside space-y-1">
              <li><strong>Nome:</strong> Identificação única do tipo de exame</li>
              <li><strong>Unidade:</strong> Unidade de medida (mg/dL, g/L, mmol/L, etc.)</li>
              <li><strong>Descrição:</strong> Descrição detalhada do exame</li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Faixa de Referência:</h4>
            <ul className="list-disc list-inside space-y-1">
              <li>Formato de intervalo: &quot;70-99&quot; para valores entre 70 e 99</li>
              <li>Formato de máximo: &quot;&lt; 200&quot; para valores menores que 200</li>
              <li>Formato de mínimo: &quot;&gt; 50&quot; para valores maiores que 50</li>
              <li>Exemplo: &quot;70-99 mg/dL&quot; ou &quot;&lt; 200 mg/dL&quot;</li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Dicas Importantes:</h4>
            <ul className="list-disc list-inside space-y-1">
              <li>Use nomes padronizados para facilitar o upload de resultados</li>
              <li>A unidade deve corresponder exatamente ao que será usado nos CSVs</li>
              <li>Faixas de referência ajudam na interpretação automática dos resultados</li>
              <li>Tipos de exame não podem ser excluídos se possuírem solicitações associadas</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

// Componente Modal para Formulário de Tipo de Exame
const ExamTypeFormModal = ({ title, examType = null, onSubmit, onClose }) => {
  const [formData, setFormData] = useState({
    name: examType?.name || '',
    description: examType?.description || '',
    unit: examType?.unit || '',
    reference_range: examType?.reference_range || ''
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.name || !formData.description || !formData.unit) {
      alert('Nome, descrição e unidade são obrigatórios');
      return;
    }

    setLoading(true);
    await onSubmit(formData);
    setLoading(false);
  };

  // Exemplos de unidades comuns
  const commonUnits = [
    'mg/dL', 'g/dL', 'g/L', 'mmol/L', 'mEq/L', 'IU/L', 'U/L', 
    'ng/mL', 'pg/mL', 'μg/dL', 'μg/L', '%', 'ratio', 'index'
  ];

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-11/12 max-w-lg shadow-lg rounded-md bg-white">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold text-gray-900">{title}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nome do Exame *
            </label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({...formData, name: e.target.value})}
              className="input-field"
              placeholder="Ex: Glucose, Cholesterol, Hemoglobin"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Descrição *
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              className="input-field"
              rows={3}
              placeholder="Descrição detalhada do exame..."
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Unidade de Medida *
            </label>
            <div className="flex space-x-2">
              <input
                type="text"
                value={formData.unit}
                onChange={(e) => setFormData({...formData, unit: e.target.value})}
                className="input-field flex-1"
                placeholder="Ex: mg/dL, g/L"
                required
              />
              <select
                value=""
                onChange={(e) => setFormData({...formData, unit: e.target.value})}
                className="input-field w-24"
              >
                <option value="">Comum</option>
                {commonUnits.map(unit => (
                  <option key={unit} value={unit}>{unit}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Faixa de Referência
            </label>
            <input
              type="text"
              value={formData.reference_range}
              onChange={(e) => setFormData({...formData, reference_range: e.target.value})}
              className="input-field"
              placeholder="Ex: 70-99 mg/dL, < 200 mg/dL"
            />
            <p className="mt-1 text-xs text-gray-500">
              Formato: &quot;min-max&quot;, &quot;&lt; valor&quot; ou &quot;&gt; valor&quot;. Exemplo: &quot;70-99&quot; ou &quot;&lt; 200&quot;
            </p>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h4 className="text-sm font-medium text-blue-900 mb-2">Exemplos de Tipos de Exame:</h4>
            <div className="text-xs text-blue-700 space-y-1">
              <div><strong>Glucose:</strong> mg/dL, faixa: &quot;70-99&quot;</div>
              <div><strong>Cholesterol:</strong> mg/dL, faixa: &quot;&lt; 200&quot;</div>
              <div><strong>Hemoglobin:</strong> g/dL, faixa: &quot;13-17&quot;</div>
              <div><strong>Triglycerides:</strong> mg/dL, faixa: &quot;&lt; 150&quot;</div>
            </div>
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <button type="button" onClick={onClose} className="btn-secondary">
              Cancelar
            </button>
            <button
              type="submit"
              disabled={loading}
              className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
            >
              {loading ? (
                <>
                  <LoadingSpinner size="sm" className="mr-2" />
                  Salvando...
                </>
              ) : (
                examType ? 'Atualizar' : 'Criar'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AdminExamTypes;