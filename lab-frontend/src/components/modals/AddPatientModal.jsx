import React, { useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../common/LoadingSpinner';
import {
  XMarkIcon,
  UserPlusIcon,
  MagnifyingGlassIcon,
  UserIcon,
  EnvelopeIcon,
  PhoneIcon
} from '@heroicons/react/24/outline';

const AddPatientModal = ({ isOpen, onClose, onSuccess }) => {
  const { user } = useAuth();
  const { request } = useApi();
  
  const [activeTab, setActiveTab] = useState('search'); // 'search' ou 'email'
  const [searchTerm, setSearchTerm] = useState('');
  const [patientEmail, setPatientEmail] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState('');

  const searchPatients = async () => {
    if (!searchTerm.trim()) {
      setError('Digite um termo para buscar');
      return;
    }

    try {
      setSearching(true);
      setError('');
      
      const response = await request({
        method: 'GET',
        url: `/doctors/${user.id}/search_patients?search=${encodeURIComponent(searchTerm)}`
      });

      if (response.data) {
        setSearchResults(response.data.patients || []);
        if (response.data.patients.length === 0) {
          setError('Nenhum paciente encontrado com este termo');
        }
      } else {
        setError('Erro ao buscar pacientes');
      }
    } catch (err) {
      setError('Erro ao buscar pacientes');
      console.error('Erro na busca:', err);
    } finally {
      setSearching(false);
    }
  };

  const addPatientByEmail = async () => {
    if (!patientEmail.trim()) {
      setError('Digite o email do paciente');
      return;
    }

    try {
      setAdding(true);
      setError('');
      
      const response = await request({
        method: 'POST',
        url: `/doctors/${user.id}/add_patient`,
        data: {
          patient_email: patientEmail.trim()
        }
      });

      if (response.data && !response.error) {
        onSuccess && onSuccess(response.data.patient);
        onClose();
        resetForm();
        alert('Paciente adicionado com sucesso!');
      } else {
        setError(response.error || 'Erro ao adicionar paciente');
      }
    } catch (err) {
      setError('Erro ao adicionar paciente');
      console.error('Erro ao adicionar:', err);
    } finally {
      setAdding(false);
    }
  };

  const addSelectedPatient = async (patient) => {
    try {
      setAdding(true);
      setError('');
      
      const response = await request({
        method: 'POST',
        url: `/doctors/${user.id}/add_patient`,
        data: {
          patient_email: patient.email
        }
      });

      if (response.data && !response.error) {
        onSuccess && onSuccess(response.data.patient);
        onClose();
        resetForm();
        alert('Paciente adicionado com sucesso!');
      } else {
        setError(response.error || 'Erro ao adicionar paciente');
      }
    } catch (err) {
      setError('Erro ao adicionar paciente');
      console.error('Erro ao adicionar:', err);
    } finally {
      setAdding(false);
    }
  };

  const resetForm = () => {
    setSearchTerm('');
    setPatientEmail('');
    setSearchResults([]);
    setError('');
    setActiveTab('search');
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-11/12 max-w-2xl shadow-lg rounded-md bg-white">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center">
            <UserPlusIcon className="h-8 w-8 text-primary-600 mr-3" />
            <h2 className="text-xl font-bold text-gray-900">Adicionar Paciente</h2>
          </div>
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex space-x-1 mb-6 bg-gray-100 p-1 rounded-lg">
          <button
            onClick={() => setActiveTab('search')}
            className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'search'
                ? 'bg-white text-primary-600 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            <MagnifyingGlassIcon className="h-4 w-4 inline mr-2" />
            Buscar Paciente
          </button>
          <button
            onClick={() => setActiveTab('email')}
            className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'email'
                ? 'bg-white text-primary-600 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            <EnvelopeIcon className="h-4 w-4 inline mr-2" />
            Por Email
          </button>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
            <p className="text-sm text-red-800">{error}</p>
          </div>
        )}

        {/* Tab Content */}
        <div className="space-y-4">
          {activeTab === 'search' && (
            <div>
              <div className="flex space-x-3 mb-4">
                <div className="flex-1">
                  <input
                    type="text"
                    placeholder="Digite nome ou email do paciente..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && searchPatients()}
                    className="input-field"
                  />
                </div>
                <button
                  onClick={searchPatients}
                  disabled={searching || !searchTerm.trim()}
                  className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                >
                  {searching ? (
                    <LoadingSpinner size="sm" />
                  ) : (
                    <>
                      <MagnifyingGlassIcon className="h-4 w-4 mr-2" />
                      Buscar
                    </>
                  )}
                </button>
              </div>

              {/* Search Results */}
              {searchResults.length > 0 && (
                <div className="border border-gray-200 rounded-lg max-h-60 overflow-y-auto">
                  {searchResults.map((patient) => (
                    <div
                      key={patient.id}
                      className="p-4 border-b border-gray-200 last:border-b-0 hover:bg-gray-50 flex justify-between items-center"
                    >
                      <div className="flex items-center space-x-3">
                        <UserIcon className="h-8 w-8 text-gray-400" />
                        <div>
                          <h4 className="text-sm font-medium text-gray-900">{patient.name}</h4>
                          <p className="text-sm text-gray-500">{patient.email}</p>
                          {patient.phone && (
                            <p className="text-sm text-gray-500">{patient.phone}</p>
                          )}
                        </div>
                      </div>
                      <button
                        onClick={() => addSelectedPatient(patient)}
                        disabled={adding}
                        className="btn-primary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {adding ? <LoadingSpinner size="sm" /> : 'Adicionar'}
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {searchTerm && searchResults.length === 0 && !searching && !error && (
                <div className="text-center py-8 text-gray-500">
                  <UserIcon className="mx-auto h-12 w-12 text-gray-300" />
                  <p className="mt-2 text-sm">Faça uma busca para ver pacientes disponíveis</p>
                </div>
              )}
            </div>
          )}

          {activeTab === 'email' && (
            <div>
              <div className="space-y-4">
                <div>
                  <label htmlFor="patient-email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email do Paciente
                  </label>
                  <input
                    id="patient-email"
                    type="email"
                    placeholder="paciente@email.com"
                    value={patientEmail}
                    onChange={(e) => setPatientEmail(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && addPatientByEmail()}
                    className="input-field"
                  />
                  <p className="mt-1 text-sm text-gray-500">
                    Digite o email exato do paciente que deseja adicionar
                  </p>
                </div>

                <button
                  onClick={addPatientByEmail}
                  disabled={adding || !patientEmail.trim()}
                  className="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                >
                  {adding ? (
                    <>
                      <LoadingSpinner size="sm" className="mr-2" />
                      Adicionando...
                    </>
                  ) : (
                    <>
                      <UserPlusIcon className="h-4 w-4 mr-2" />
                      Adicionar Paciente
                    </>
                  )}
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Information */}
        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-md p-4">
          <h4 className="text-sm font-medium text-blue-900 mb-2">Informações Importantes</h4>
          <div className="text-sm text-blue-700 space-y-1">
            <p>• Você só pode adicionar pacientes já cadastrados no sistema</p>
            <p>• Use a busca para encontrar pacientes por nome ou email</p>
            <p>• Ou adicione diretamente pelo email se souber o endereço exato</p>
            <p>• Após adicionar, você poderá criar solicitações de exames para este paciente</p>
          </div>
        </div>

        {/* Cancel Button */}
        <div className="mt-6 flex justify-end">
          <button
            onClick={handleClose}
            className="btn-secondary"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  );
};

export default AddPatientModal;