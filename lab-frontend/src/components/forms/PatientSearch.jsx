import React, { useState, useEffect, useCallback } from 'react';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../common/LoadingSpinner';
import { 
  MagnifyingGlassIcon, 
  UserIcon,
  CheckIcon,
  PlusIcon
} from '@heroicons/react/24/outline';

const PatientSearch = ({ onPatientSelect, selectedPatient = null, className = '' }) => {
  const { request } = useApi();
  const [searchTerm, setSearchTerm] = useState('');
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const [allPatients, setAllPatients] = useState([]);
  const [loadingAll, setLoadingAll] = useState(false);

  // Buscar todos os pacientes ao carregar o componente
  const fetchAllPatients = useCallback(async () => {
    try {
      setLoadingAll(true);
      const response = await request({
        method: 'GET',
        url: '/doctors/all_patients?limit=100'
      });
      
      if (response.data) {
        setAllPatients(response.data.patients || []);
      }
    } catch (error) {
      console.error('Erro ao buscar todos os pacientes:', error);
    } finally {
      setLoadingAll(false);
    }
  }, [request]);

  useEffect(() => {
    fetchAllPatients();
  }, [fetchAllPatients]);

  // Buscar pacientes baseado no termo de busca
  const searchPatients = useCallback(async (term) => {
    if (!term || term.length < 2) {
      setPatients([]);
      return;
    }

    try {
      setLoading(true);
      const response = await request({
        method: 'GET',
        url: `/doctors/search_patients?search=${encodeURIComponent(term)}`
      });
      
      if (response.data) {
        setPatients(response.data.patients || []);
      }
    } catch (error) {
      console.error('Erro ao buscar pacientes:', error);
      setPatients([]);
    } finally {
      setLoading(false);
    }
  }, [request]);

  // Debounce da busca
  useEffect(() => {
    const timer = setTimeout(() => {
      searchPatients(searchTerm);
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm, searchPatients]);

  const handleInputChange = (e) => {
    const value = e.target.value;
    setSearchTerm(value);
    setShowDropdown(true);
    
    // Se limpar o campo, limpar seleção
    if (!value) {
      onPatientSelect(null);
    }
  };

  const handlePatientSelect = (patient) => {
    setSearchTerm(patient.name);
    setShowDropdown(false);
    onPatientSelect(patient);
  };

  const handleFocus = () => {
    setShowDropdown(true);
  };

  const handleBlur = () => {
    // Delay para permitir clique no dropdown
    setTimeout(() => setShowDropdown(false), 200);
  };

  // Combinar resultados da busca com todos os pacientes
  const getDisplayPatients = () => {
    if (searchTerm && searchTerm.length >= 2) {
      return patients;
    }
    
    // Se não há busca, mostrar todos os pacientes
    return allPatients.slice(0, 10);
  };

  const displayPatients = getDisplayPatients();

  return (
    <div className={`relative ${className}`}>
      <label className="block text-sm font-medium text-gray-700 mb-2">
        Buscar Paciente *
      </label>
      
      <div className="relative">
        <input
          type="text"
          value={searchTerm}
          onChange={handleInputChange}
          onFocus={handleFocus}
          onBlur={handleBlur}
          placeholder="Digite o nome ou email do paciente..."
          className="input-field pl-10"
          autoComplete="off"
        />
        
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          {loading ? (
            <LoadingSpinner size="sm" />
          ) : (
            <MagnifyingGlassIcon className="h-5 w-5 text-gray-400" />
          )}
        </div>

        {selectedPatient && (
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            <CheckIcon className="h-5 w-5 text-green-500" />
          </div>
        )}
      </div>

      {/* Dropdown com resultados */}
      {showDropdown && (
        <div className="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
          {loadingAll && displayPatients.length === 0 ? (
            <div className="flex items-center justify-center py-4">
              <LoadingSpinner size="sm" />
              <span className="ml-2 text-gray-500">Carregando pacientes...</span>
            </div>
          ) : displayPatients.length > 0 ? (
            <>
              {searchTerm && searchTerm.length >= 2 && (
                <div className="px-3 py-2 text-xs font-medium text-gray-500 bg-gray-50">
                  {patients.length} resultado(s) encontrado(s)
                </div>
              )}
              
              {displayPatients.map((patient) => (
                <div
                  key={patient.id}
                  onClick={() => handlePatientSelect(patient)}
                  className="cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-gray-50"
                >
                  <div className="flex items-center">
                    <UserIcon className="h-5 w-5 text-gray-400 mr-3 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-gray-900 truncate">
                        {patient.name}
                      </div>
                      <div className="text-sm text-gray-500 truncate">
                        {patient.email}
                      </div>
                      {patient.phone && (
                        <div className="text-xs text-gray-400">
                          {patient.phone}
                        </div>
                      )}
                    </div>
                  </div>
                  
                  {selectedPatient?.id === patient.id && (
                    <div className="absolute inset-y-0 right-0 flex items-center pr-4">
                      <CheckIcon className="h-5 w-5 text-green-600" />
                    </div>
                  )}
                </div>
              ))}
            </>
          ) : searchTerm && searchTerm.length >= 2 ? (
            <div className="px-3 py-4 text-center text-gray-500">
              <UserIcon className="mx-auto h-6 w-6 text-gray-400 mb-2" />
              <div className="text-sm">Nenhum paciente encontrado</div>
              <div className="text-xs">Tente buscar por nome ou email</div>
            </div>
          ) : (
            <div className="px-3 py-4 text-center text-gray-500">
              <div className="text-sm">Digite pelo menos 2 caracteres para buscar</div>
              <div className="text-xs mt-1">ou veja todos os pacientes abaixo</div>
              {allPatients.length > 0 && (
                <div className="mt-2 text-xs text-gray-400">
                  Mostrando {Math.min(10, allPatients.length)} de {allPatients.length} pacientes
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Informação do paciente selecionado */}
      {selectedPatient && (
        <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-md">
          <div className="flex items-center">
            <UserIcon className="h-5 w-5 text-green-600 mr-2" />
            <div className="flex-1">
              <div className="text-sm font-medium text-green-900">
                Paciente Selecionado:
              </div>
              <div className="text-sm text-green-700">
                {selectedPatient.name} - {selectedPatient.email}
              </div>
            </div>
            <button
              onClick={() => {
                setSearchTerm('');
                onPatientSelect(null);
              }}
              className="text-green-600 hover:text-green-800"
            >
              <span className="sr-only">Remover seleção</span>
              ×
            </button>
          </div>
        </div>
      )}

      {/* Dica de uso */}
      <p className="mt-2 text-xs text-gray-500">
        {searchTerm && searchTerm.length < 2
          ? 'Digite pelo menos 2 caracteres para buscar pacientes'
          : 'Busque por nome ou email, ou selecione da lista'
        }
      </p>
    </div>
  );
};

export default PatientSearch;