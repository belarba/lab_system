import React, { useState, useRef } from 'react';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import {
  DocumentArrowUpIcon,
  DocumentTextIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  CloudArrowUpIcon
} from '@heroicons/react/24/outline';

const UploadResults = () => {
  const { request } = useApi();
  const fileInputRef = useRef(null);
  
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState(null);
  const [dragActive, setDragActive] = useState(false);

  const handleFileSelect = (file) => {
    if (!file) return;

    // Validar tipo de arquivo
    const allowedTypes = ['.csv', '.xlsx', '.xls'];
    const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
    
    if (!allowedTypes.includes(fileExtension)) {
      alert('Por favor, selecione apenas arquivos CSV ou Excel (.xlsx, .xls)');
      return;
    }

    // Validar tamanho (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      alert('O arquivo deve ter no máximo 10MB');
      return;
    }

    setSelectedFile(file);
    setUploadResult(null);
  };

  const handleFileInput = (e) => {
    const file = e.target.files[0];
    handleFileSelect(file);
  };

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileSelect(e.dataTransfer.files[0]);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    try {
      setUploading(true);
      
      const formData = new FormData();
      formData.append('file', selectedFile);

      const response = await request({
        method: 'POST',
        url: '/uploads',
        data: formData,
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      if (response.data && !response.error) {
        setUploadResult(response.data);
        setSelectedFile(null);
        // Reset file input
        if (fileInputRef.current) {
          fileInputRef.current.value = '';
        }
      } else {
        alert(`Erro no upload: ${response.error}`);
      }
    } catch (error) {
      console.error('Erro no upload:', error);
      alert('Erro no upload. Tente novamente.');
    } finally {
      setUploading(false);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Upload de Resultados</h1>
        <p className="mt-2 text-gray-600">
          Faça upload de arquivos CSV ou Excel com resultados laboratoriais
        </p>
      </div>

      {/* Upload Area */}
      <div className="card">
        <div className="flex items-center mb-6">
          <DocumentArrowUpIcon className="h-8 w-8 text-primary-600 mr-3" />
          <h2 className="text-xl font-semibold text-gray-900">
            Selecionar Arquivo
          </h2>
        </div>

        {/* Drag & Drop Area */}
        <div
          className={`relative border-2 border-dashed rounded-lg p-6 transition-colors ${
            dragActive 
              ? 'border-primary-500 bg-primary-50' 
              : 'border-gray-300 hover:border-gray-400'
          }`}
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
        >
          <div className="text-center">
            <CloudArrowUpIcon className="mx-auto h-12 w-12 text-gray-400" />
            <div className="mt-4">
              <label htmlFor="file-upload" className="cursor-pointer">
                <span className="mt-2 block text-sm font-medium text-gray-900">
                  Arraste um arquivo aqui ou clique para selecionar
                </span>
                <input
                  ref={fileInputRef}
                  id="file-upload"
                  name="file-upload"
                  type="file"
                  className="sr-only"
                  accept=".csv,.xlsx,.xls"
                  onChange={handleFileInput}
                />
              </label>
              <p className="mt-2 text-xs text-gray-500">
                CSV, XLSX, XLS até 10MB
              </p>
            </div>
          </div>
        </div>

        {/* Arquivo Selecionado */}
        {selectedFile && (
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <DocumentTextIcon className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <h4 className="text-sm font-medium text-blue-900">
                    {selectedFile.name}
                  </h4>
                  <p className="text-sm text-blue-700">
                    {formatFileSize(selectedFile.size)}
                  </p>
                </div>
              </div>
              <div className="flex space-x-3">
                <button
                  onClick={() => {
                    setSelectedFile(null);
                    if (fileInputRef.current) {
                      fileInputRef.current.value = '';
                    }
                  }}
                  className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                >
                  Remover
                </button>
                <button
                  onClick={handleUpload}
                  disabled={uploading}
                  className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                >
                  {uploading ? (
                    <>
                      <LoadingSpinner size="sm" className="mr-2" />
                      Enviando...
                    </>
                  ) : (
                    <>
                      <DocumentArrowUpIcon className="h-4 w-4 mr-2" />
                      Fazer Upload
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Resultado do Upload */}
      {uploadResult && (
        <div className="card">
          <div className="flex items-center mb-6">
            <CheckCircleIcon className="h-8 w-8 text-green-600 mr-3" />
            <h2 className="text-xl font-semibold text-gray-900">
              Resultado do Upload
            </h2>
          </div>

          <div className="space-y-6">
            {/* Status Geral */}
            <div className="flex items-center justify-between p-4 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center">
                <CheckCircleIcon className="h-6 w-6 text-green-600 mr-3" />
                <div>
                  <h4 className="text-sm font-medium text-green-900">
                    Upload Concluído
                  </h4>
                  <p className="text-sm text-green-700">
                    Arquivo: {uploadResult.upload?.filename}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <div className="text-sm font-medium text-green-900">
                  {uploadResult.upload?.success_rate}% de sucesso
                </div>
                <div className="text-xs text-green-700">
                  Status: {uploadResult.upload?.status === 'completed' ? 'Concluído' : uploadResult.upload?.status}
                </div>
              </div>
            </div>

            {/* Estatísticas */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-center">
                  <DocumentTextIcon className="h-6 w-6 text-blue-600 mr-2" />
                  <div>
                    <div className="text-lg font-semibold text-blue-900">
                      {uploadResult.upload?.total_records || 0}
                    </div>
                    <div className="text-sm text-blue-700">Total de Registros</div>
                  </div>
                </div>
              </div>

              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex items-center">
                  <CheckCircleIcon className="h-6 w-6 text-green-600 mr-2" />
                  <div>
                    <div className="text-lg font-semibold text-green-900">
                      {uploadResult.upload?.processed_records || 0}
                    </div>
                    <div className="text-sm text-green-700">Processados</div>
                  </div>
                </div>
              </div>

              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <div className="flex items-center">
                  <XCircleIcon className="h-6 w-6 text-red-600 mr-2" />
                  <div>
                    <div className="text-lg font-semibold text-red-900">
                      {uploadResult.upload?.failed_records || 0}
                    </div>
                    <div className="text-sm text-red-700">Falharam</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Ações */}
            <div className="flex justify-between items-center pt-4 border-t border-gray-200">
              <a
                href="/lab/uploads"
                className="text-primary-600 hover:text-primary-700 text-sm font-medium"
              >
                Ver Histórico de Uploads
              </a>
              <button
                onClick={() => setUploadResult(null)}
                className="btn-secondary"
              >
                Fazer Novo Upload
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Formato Esperado */}
      <div className="card">
        <div className="flex items-center mb-4">
          <ExclamationTriangleIcon className="h-8 w-8 text-amber-600 mr-3" />
          <h2 className="text-xl font-semibold text-gray-900">
            Formato Esperado do Arquivo
          </h2>
        </div>

        <div className="space-y-4">
          <p className="text-gray-600">
            O arquivo CSV deve conter as seguintes colunas (exatamente com estes nomes):
          </p>

          <div className="bg-gray-50 p-4 rounded-lg font-mono text-sm">
            <div className="font-bold text-gray-700 mb-2">Cabeçalho obrigatório:</div>
            <div className="text-gray-600">
              patient_email,test_type,measured_value,unit,measured_at
            </div>
          </div>

          <div className="space-y-2">
            <h4 className="font-medium text-gray-900">Descrição das colunas:</h4>
            <ul className="text-sm text-gray-600 space-y-1">
              <li><strong>patient_email:</strong> Email do paciente (deve existir no sistema)</li>
              <li><strong>test_type:</strong> Nome do tipo de exame (deve existir no sistema)</li>
              <li><strong>measured_value:</strong> Valor numérico do resultado</li>
              <li><strong>unit:</strong> Unidade de medida (mg/dL, g/L, etc.)</li>
              <li><strong>measured_at:</strong> Data e hora da medição (formato ISO: 2025-01-15T09:30:00Z)</li>
            </ul>
          </div>

          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-medium text-blue-900 mb-2">Exemplo de linha:</h4>
            <div className="font-mono text-sm text-blue-700">
              paciente@email.com,Glucose,95.5,mg/dL,2025-01-15T09:30:00Z
            </div>
          </div>

          <div className="text-sm text-gray-500 space-y-1">
            <p><strong>Dica:</strong> Evite espaços extras e caracteres especiais nos nomes das colunas.</p>
            <p><strong>Codificação:</strong> Salve o arquivo CSV com codificação UTF-8.</p>
            <p><strong>Separador:</strong> Use vírgula (,) como separador de campos.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UploadResults;