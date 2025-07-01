import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { 
  Bars3Icon, 
  XMarkIcon,
  UserCircleIcon,
  ArrowRightOnRectangleIcon,
  HomeIcon,
  UsersIcon,
  DocumentTextIcon,
  Cog6ToothIcon,
  BeakerIcon
} from '@heroicons/react/24/outline';

const Layout = ({ children }) => {
  const { user, logout, hasRole } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  const navigation = [
    // Navegação para pacientes
    ...(hasRole('patient') ? [
      { name: 'Dashboard', href: '/patient', icon: HomeIcon },
      { name: 'Meu Perfil', href: '/patient/profile', icon: UserCircleIcon },
      { name: 'Meus Exames', href: '/patient/exams', icon: DocumentTextIcon },
      { name: 'Solicitar Exame', href: '/patient/request', icon: BeakerIcon },
      { name: 'Resultados', href: '/patient/results', icon: DocumentTextIcon },
    ] : []),
    
    // Navegação para médicos
    ...(hasRole('doctor') ? [
      { name: 'Dashboard', href: '/doctor', icon: HomeIcon },
      { name: 'Pacientes', href: '/doctor/patients', icon: UsersIcon },
      { name: 'Solicitar Exames', href: '/doctor/exams', icon: BeakerIcon },
      { name: 'Resultados', href: '/doctor/results', icon: DocumentTextIcon },
    ] : []),
    
    // Navegação para técnicos de laboratório
    ...(hasRole('lab_technician') ? [
      { name: 'Dashboard', href: '/lab', icon: HomeIcon },
      { name: 'Upload Resultados', href: '/lab/upload', icon: DocumentTextIcon },
      { name: 'Histórico Uploads', href: '/lab/uploads', icon: BeakerIcon },
    ] : []),
    
    // Navegação para administradores
    ...(hasRole('admin') ? [
      { name: 'Dashboard', href: '/admin', icon: HomeIcon },
      { name: 'Usuários', href: '/admin/users', icon: UsersIcon },
      { name: 'Tipos de Exame', href: '/admin/exam-types', icon: BeakerIcon },
      { name: 'Sistema', href: '/admin/system', icon: Cog6ToothIcon },
    ] : []),
  ];

  const handleLogout = async () => {
    await logout();
  };

  const isCurrentPath = (href) => {
    if (href === '/patient' || href === '/doctor' || href === '/lab' || href === '/admin') {
      return location.pathname === href;
    }
    return location.pathname.startsWith(href);
  };

  const NavLink = ({ item, mobile = false }) => (
    <Link
      to={item.href}
      className={`group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold transition-colors ${
        isCurrentPath(item.href)
          ? 'bg-primary-100 text-primary-700'
          : 'text-gray-700 hover:text-primary-600 hover:bg-gray-50'
      }`}
      onClick={mobile ? () => setSidebarOpen(false) : undefined}
    >
      <item.icon className={`h-6 w-6 shrink-0 ${
        isCurrentPath(item.href) ? 'text-primary-600' : 'text-gray-400 group-hover:text-primary-600'
      }`} />
      {item.name}
    </Link>
  );

  return (
    <div className="min-h-full">
      {/* Mobile sidebar */}
      <div className={`relative z-50 lg:hidden ${sidebarOpen ? '' : 'hidden'}`}>
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75" onClick={() => setSidebarOpen(false)}></div>
        <div className="fixed inset-0 flex">
          <div className="relative mr-16 flex w-full max-w-xs flex-1">
            <div className="absolute left-full top-0 flex w-16 justify-center pt-5">
              <button type="button" className="-m-2.5 p-2.5" onClick={() => setSidebarOpen(false)}>
                <XMarkIcon className="h-6 w-6 text-white" />
              </button>
            </div>
            <div className="flex grow flex-col gap-y-5 overflow-y-auto bg-white px-6 pb-2">
              <div className="flex h-16 shrink-0 items-center">
                <h1 className="text-xl font-bold text-primary-600">Lab System</h1>
              </div>
              <nav className="flex flex-1 flex-col">
                <ul className="flex flex-1 flex-col gap-y-7">
                  <li>
                    <ul className="-mx-2 space-y-1">
                      {navigation.map((item) => (
                        <li key={item.name}>
                          <NavLink item={item} mobile={true} />
                        </li>
                      ))}
                    </ul>
                  </li>
                </ul>
              </nav>
            </div>
          </div>
        </div>
      </div>

      {/* Static sidebar for desktop */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
        <div className="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6">
          <div className="flex h-16 shrink-0 items-center">
            <h1 className="text-xl font-bold text-primary-600">Lab System</h1>
          </div>
          <nav className="flex flex-1 flex-col">
            <ul className="flex flex-1 flex-col gap-y-7">
              <li>
                <ul className="-mx-2 space-y-1">
                  {navigation.map((item) => (
                    <li key={item.name}>
                      <NavLink item={item} />
                    </li>
                  ))}
                </ul>
              </li>
            </ul>
          </nav>
        </div>
      </div>

      <div className="lg:pl-72">
        {/* Top bar */}
        <div className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <button
            type="button"
            className="-m-2.5 p-2.5 text-gray-700 lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Bars3Icon className="h-6 w-6" />
          </button>

          <div className="h-6 w-px bg-gray-200 lg:hidden" />

          <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div className="relative flex flex-1"></div>
            <div className="flex items-center gap-x-4 lg:gap-x-6">
              {/* User menu */}
              <div className="flex items-center gap-x-4">
                <span className="text-sm font-semibold leading-6 text-gray-900">
                  {user?.name}
                </span>
                <UserCircleIcon className="h-8 w-8 text-gray-400" />
                <button
                  onClick={handleLogout}
                  className="flex items-center gap-x-2 text-sm font-semibold leading-6 text-gray-900 hover:text-primary-600"
                >
                  <ArrowRightOnRectangleIcon className="h-5 w-5" />
                  Sair
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Main content */}
        <main className="py-10">
          <div className="px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default Layout;