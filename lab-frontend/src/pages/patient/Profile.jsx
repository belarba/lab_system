import React, { useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useApi } from '../../hooks/useApi';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { UserCircleIcon, PhoneIcon, EnvelopeIcon, CalendarIcon } from '@heroicons/react/24/outline';

const PatientProfile = () => {
  const { user, updateUser } = useAuth();
  const { request, loading } = useApi();
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || ''
  });
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      const response = await request({
        method: 'PUT',
        url: '/users/me',
        data: {
          user: {
            name: formData.name,
            phone: formData.phone,
            email: formData.email
          }
        }
      });

      if (response.data && !response.error) {
        updateUser(response.data.user);
        setSuccess('Perfil atualizado com sucesso!');
        setIsEditing(false);
        
        // Limpar mensagem de sucesso após 3 segundos
        setTimeout(() => setSuccess(''), 3000);
      } else {
        setError(response.error || 'Erro ao atualizar perfil');
      }
    } catch {
      setError('Erro ao atualizar perfil');
    }
  };

  const handleCancel = () => {
    setFormData({
      name: user?.name || '',
      email: user?.email || '',
      phone: user?.phone || ''
    });
    setIsEditing(false);
    setError('');
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Meu Perfil</h1>
          <p className="text-gray-600">Gerencie suas informações pessoais</p>
        </div>
        {!isEditing && (
          <button
            onClick={() => setIsEditing(true)}
            className="btn-primary"
          >
            Editar Perfil
          </button>
        )}
      </div>

      {/* Mensagens de feedback */}
      {success && (
        <div className="bg-green-50 border border-green-200 rounded-md p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-green-800">{success}</p>
            </div>
          </div>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{error}</p>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Informações Pessoais */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="flex items-center mb-6">
              <UserCircleIcon className="h-8 w-8 text-primary-600 mr-3" />
              <h2 className="text-xl font-semibold text-gray-900">Informações Pessoais</h2>
            </div>

            {isEditing ? (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                    Nome Completo
                  </label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    className="input-field"
                  />
                </div>

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    required
                    className="input-field"
                  />
                </div>

                <div>
                  <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                    Telefone/Celular
                  </label>
                  <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    placeholder="+351 91 234 5678"
                    className="input-field"
                  />
                  <p className="mt-1 text-sm text-gray-500">
                    Formato: +351 91 234 5678
                  </p>
                </div>

                <div className="flex space-x-3 pt-4">
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
                      'Salvar Alterações'
                    )}
                  </button>
                  <button
                    type="button"
                    onClick={handleCancel}
                    className="btn-secondary"
                    disabled={loading}
                  >
                    Cancelar
                  </button>
                </div>
              </form>
            ) : (
              <div className="space-y-6">
                <div className="flex items-center">
                  <UserCircleIcon className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Nome</p>
                    <p className="text-lg text-gray-900">{user?.name}</p>
                  </div>
                </div>

                <div className="flex items-center">
                  <EnvelopeIcon className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Email</p>
                    <p className="text-lg text-gray-900">{user?.email}</p>
                  </div>
                </div>

                <div className="flex items-center">
                  <PhoneIcon className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Telefone</p>
                    <p className="text-lg text-gray-900">
                      {user?.phone || 'Não informado'}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Informações da Conta */}
        <div>
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Informações da Conta</h3>
            
            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-500">Tipo de Usuário</p>
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  Paciente
                </span>
              </div>

              <div>
                <p className="text-sm font-medium text-gray-500">Membro desde</p>
                <div className="flex items-center">
                  <CalendarIcon className="h-4 w-4 text-gray-400 mr-2" />
                  <p className="text-sm text-gray-900">
                    {new Date(user?.created_at).toLocaleDateString('pt-BR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })}
                  </p>
                </div>
              </div>

              <div>
                <p className="text-sm font-medium text-gray-500">Última atualização</p>
                <p className="text-sm text-gray-900">
                  {new Date(user?.updated_at).toLocaleDateString('pt-BR')}
                </p>
              </div>
            </div>
          </div>

          {/* Dicas de Segurança */}
          <div className="card mt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Dicas de Segurança</h3>
            <div className="space-y-3 text-sm text-gray-600">
              <p>• Mantenha suas informações atualizadas</p>
              <p>• Use um telefone válido para contato emergencial</p>
              <p>• Verifique regularmente seus dados</p>
              <p>• Em caso de problemas, entre em contato conosco</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PatientProfile;