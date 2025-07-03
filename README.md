

## **Sistema de Exames Laboratoriais**

Sistema completo para gestão de exames laboratoriais com diferentes perfis de usuário: pacientes, médicos, técnicos de laboratório e administradores.

🏗️ Arquitetura

---------------
*  **Backend**: Ruby on Rails 8.0 API

*  **Frontend**: React + Vite

*  **Banco de Dados**: PostgreSQL

*	 **Load Balancer**: Nginx

*  **Containerização**: Docker + Docker Compose

*  **Autenticação**: JWT com refresh tokens

*  **Styling**: Tailwind CSS
  

📋 Funcionalidades Principais

-----------------------------

  

###  👥 Perfis de Usuário

  

####  Pacientes

  

* Dashboard com visão geral dos exames

* Solicitar exames laboratoriais (autosserviço)

* Visualizar histórico de resultados

* Cancelar agendamentos (até 3h antes)

* Gráficos de tendência dos resultados

  

####  Médicos

  

* Gerenciar lista de pacientes

* Solicitar exames para pacientes

* Visualizar resultados dos pacientes

* Exportar relatórios em CSV

* Dashboard com estatísticas

  

####  Técnicos de Laboratório

  

* Upload de resultados via CSV/XLSX

* Processamento automático de dados

* Histórico de uploads com status

* Tratamento de erros de importação

  

####  Administradores

  

* Gestão completa de usuários

* Configuração de tipos de exame

* Estatísticas do sistema

* Gerenciamento de roles

  

🐳 Setup com Docker (Recomendado)

---------------

###  Pré-requisitos

* Docker 20.0+
* Docker Compose 2.0+

### 🚀 Início Rápido

1.Clone o repositório
```
bashgit clone <url-do-repo>
cd <nome-do-projeto>
```
2.Execute o script de setup
```
bashchmod +x scripts/docker-setup.sh
./scripts/docker-setup.sh
```
3.Inicie os serviços
```
bashdocker-compose up -d
```
4.Acesse a aplicação


Frontend: `http://localhost:5173`
API (Load Balanced): `http://localhost:9999`
Backend 1: `http://localhost:3001`
Backend 2: `http://localhost:3002`

### 🛠️ Comandos de Desenvolvimento
```
# Usar script helper
chmod +x scripts/docker-dev.sh

# Iniciar ambiente
./scripts/docker-dev.sh start

# Ver logs
./scripts/docker-dev.sh logs

# Rails console
./scripts/docker-dev.sh console

# Executar testes
./scripts/docker-dev.sh test

# Resetar banco
./scripts/docker-dev.sh reset
```

### 📊 Arquitetura Docker
┌─────────────────┐    ┌──────────────┐
│   Frontend      │    │    Nginx     │
│   (React+Vite)  │    │ Load Balancer│
│   Port: 5173    │    │  Port: 9999  │
└─────────────────┘    └──────┬───────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
            ┌───────▼────┐    ┌─────────▼──┐
            │ Backend 01 │    │ Backend 02 │
            │Rails API   │    │Rails API   │
            │Port: 3001  │    │Port: 3002  │
            └─────┬──────┘    └─────┬──────┘
                  │                 │
                  └─────────┬───────┘
                            │
                    ┌───────▼────┐
                    │PostgreSQL  │
                    │Port: 5432  │
                    └────────────┘

### 🔧 Configuração Personalizada

Variáveis de Ambiente (`.env` na raiz):
```
# Rails
RAILS_MASTER_KEY=your-master-key-here
RAILS_ENV=development

# Database  
DATABASE_HOST=db
DATABASE_USERNAME=lab
DATABASE_PASSWORD=lab123

# Frontend
VITE_API_BASE_URL=http://localhost:9999
```

🚀 Setup Manual (Sem Docker)


---------------

  

###  Pré-requisitos

  

* Ruby 3.4.2

* Node.js 18+

* PostgreSQL 12+

* Git

  

###  🔧 Setup do Backend (Rails API)

  

1.  **Clone o repositório**

  

```
	git clone <url-do-repo>
	cd <nome-do-projeto>
```

  

2.  **Navegue para a pasta do backend**

  

```
	cd backend_api
```

  

3.  **Instale as dependências**

  

```
	bundle install
```

  

4.  **Configure o banco de dados**

  

```
	# Copie o arquivo de exemplo de configuração
	cp config/database.yml.example config/database.yml

	# Configure as variáveis de ambiente
	cp .env.example .env
```

  

5.  **Configure as variáveis de ambiente no arquivo `.env`**

```
	DATABASE_USERNAME=seu_usuario_postgres
	DATABASE_PASSWORD=sua_senha_postgres
	DATABASE_HOST=localhost
```

  

6.  **Execute as migrações e seeds**

```
	rails db:create
	rails db:migrate
	rails db:seed
```

  

7.  **Inicie o servidor**

```
	rails server
```

  

O backend estará rodando em: `http://localhost:3000`

  

###  🎨 Setup do Frontend (React)

  

1.  **Em um novo terminal, navegue para a pasta do frontend**

```
	cd lab-frontend
```

  

2.  **Instale as dependências**

```
	npm install
```

  

3.  **Configure as variáveis de ambiente `.env`**

```
	VITE_API_BASE_URL=url_do_backend
```

  

4.  **Inicie o servidor de desenvolvimento**

```
	npm run dev
```

  

O frontend estará rodando em: `http://localhost:5173`

  

👤 Usuários de Teste

--------------------

  

Após executar `rails db:seed`, você terá os seguintes usuários disponíveis:

| Tipo | Email | Senha | Descrição |
|--|--|--|--|
| Admin | admin@labsystem.pt | admin123 | Acesso completo ao sistema |
| Médico | luiscosta@clinic.pt | password123 | Pode solicitar e ver exames |
| Paciente | anasilva@health.pt | password123 | Pode solicitar e ver exames |
| Lab Tech | mariorodas@lusagua.pt | password123 | Pode fazer upload de resultados |

  

🧪 Executar Testes

------------------

  

###  Backend (RSpec)

```
	cd backend_api
	bundle exec rspec
```
  

###  Frontend (Vitest)

```
	cd lab-frontend
	npm test
```

📡 API Endpoints Principais

---------------------------

  

###  Autenticação

  

* `POST /api/auth/login` - Login

* `POST /api/auth/logout` - Logout

* `POST /api/auth/refresh` - Renovar token

  

###  Exames

  

* `GET /api/exam_types` - Listar tipos de exame

* `POST /api/blood_work_requests` - Solicitar exame (médico)

* `POST /api/patient/requests` - Solicitar exame (paciente)

* `GET /api/patients/:id/test_results` - Resultados do paciente

  

###  Upload de Resultados

  

* `POST /api/uploads` - Upload de arquivo CSV

* `GET /api/uploads` - Histórico de uploads

  

###  Administração

  

* `GET /api/admin/users` - Gerenciar usuários

* `GET /api/admin/exam_types` - Gerenciar tipos de exame

* `GET /api/admin/stats` - Estatísticas do sistema

  

📁 Estrutura do Projeto

-----------------------

├── backend_api/              # Rails API  
│   ├── app/  
│   │   ├── controllers/      # Controllers da API  
│   │   ├── models/          # Models do Rails  
│   │   └── services/        # Services (CSV import, JWT)  
│   ├── config/              # Configurações  
│   ├── db/                  # Migrações e seeds  
│   └── spec/                # Testes RSpec  
│  
├── lab-frontend/            # React App  
│   ├── src/  
│   │   ├── components/      # Componentes React  
│   │   ├── pages/          # Páginas por perfil  
│   │   ├── hooks/          # Custom hooks  
│   │   ├── contexts/       # Context providers  
│   │   └── services/       # API client  
│   └── public/             # Assets estáticos  
  
  

🔒 Segurança

------------

  

* Autenticação JWT com refresh tokens

* CORS configurado

* Validações de permissão por role

* Sanitização de parâmetros

* Rate limiting (configurável)

  

📊 Funcionalidades Técnicas

---------------------------

  

*  **Upload CSV**: Processamento assíncrono de resultados laboratoriais

*  **Gráficos**: Visualização de tendências com Recharts

*  **Exportação**: Relatórios em CSV para médicos

*  **Responsivo**: Interface adaptável a dispositivos móveis

*  **Testes**: Cobertura de testes unitários e de integração

  

🛠️ Desenvolvimento

-------------------

  

###  Comandos Úteis

  

**Backend:**

  

```
	# Executar linter
	bin/rubocop

	# Executar análise de segurança
	bin/brakeman

	# Console do Rails
	rails console
```

  

**Frontend:**

  

```
	# Linter
	npm run lint

	# Build para produção
	npm run build

	# Testes com UI
	npm run test:ui
```

  

🚀 Deploy

---------

  

###  Backend

  

O projeto está configurado para deploy com Kamal. Configure o arquivo `config/deploy.yml` com seus dados.

  

###  Frontend

  

Build de produção:

  

```
	npm run build
```

  

🐛 Solução de Problemas

-----------------------

  

###  Problemas Comuns

  

1.  **Erro de conexão com PostgreSQL**

* Verifique se o PostgreSQL está rodando

* Confirme as credenciais no `.env`

2.  **Erro 401 no frontend**

* Verifique se o backend está rodando na porta 3000

* Confirme a configuração da `VITE_API_BASE_URL`

3.  **Falha no upload de CSV**

* Verifique o formato: `patient_email,test_type,measured_value,unit,measured_at`

* Confirme se os tipos de exame existem no sistema

