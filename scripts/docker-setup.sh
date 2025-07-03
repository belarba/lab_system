echo "🐳 Configurando ambiente Docker..."

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env..."
    cat > .env << EOL
# Docker Compose Environment Variables
RAILS_MASTER_KEY=$(openssl rand -hex 32)
RAILS_ENV=development

# Database
DATABASE_HOST=db
DATABASE_USERNAME=lab
DATABASE_PASSWORD=lab123
POSTGRES_PASSWORD=postgres123
POSTGRES_USER=postgres
POSTGRES_DB=lab_system

# API URL for frontend
VITE_API_BASE_URL=http://localhost:9999
EOL
fi

# Criar diretórios necessários
mkdir -p backend_api/tmp/{pids,storage}
mkdir -p backend_api/log

echo "🔨 Construindo containers..."
docker-compose build

echo "🚀 Iniciando serviços..."
docker-compose up -d db

echo "⏳ Aguardando banco de dados..."
sleep 10

echo "🗄️ Configurando banco de dados..."
docker-compose run --rm backend01 rails db:create
docker-compose run --rm backend01 rails db:migrate
docker-compose run --rm backend01 rails db:seed

echo "✅ Setup concluído!"
echo ""
echo "🌐 Acesse a aplicação em:"
echo "   Frontend: http://localhost:5173"
echo "   API Load Balancer: http://localhost:9999"
echo "   Backend 1: http://localhost:3001"
echo "   Backend 2: http://localhost:3002"
echo ""
echo "👤 Usuários de teste:"
echo "   Admin: admin@labsystem.pt / admin123"
echo "   Médico: luiscosta@clinic.pt / password123"
echo "   Paciente: anasilva@health.pt / password123"
echo "   Lab Tech: mariorodas@lusagua.pt / password123"

---

#!/bin/bash
# scripts/docker-dev.sh
# Script para desenvolvimento com Docker

case $1 in
  "start")
    echo "🚀 Iniciando ambiente de desenvolvimento..."
    docker-compose up -d
    ;;
  "stop")
    echo "🛑 Parando ambiente..."
    docker-compose down
    ;;
  "restart")
    echo "🔄 Reiniciando ambiente..."
    docker-compose restart
    ;;
  "logs")
    echo "📋 Mostrando logs..."
    docker-compose logs -f
    ;;
  "console")
    echo "🔧 Abrindo Rails console..."
    docker-compose exec backend01 rails console
    ;;
  "bash")
    echo "💻 Abrindo bash no backend..."
    docker-compose exec backend01 bash
    ;;
  "migrate")
    echo "🗄️ Executando migrações..."
    docker-compose exec backend01 rails db:migrate
    ;;
  "seed")
    echo "🌱 Executando seeds..."
    docker-compose exec backend01 rails db:seed
    ;;
  "test")
    echo "🧪 Executando testes..."
    docker-compose exec backend01 bundle exec rspec
    docker-compose exec frontend npm test
    ;;
  "reset")
    echo "🔄 Resetando banco de dados..."
    docker-compose exec backend01 rails db:drop db:create db:migrate db:seed
    ;;
  *)
    echo "🐳 Lab System - Comandos Docker"
    echo ""
    echo "Uso: ./scripts/docker-dev.sh [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  start     - Iniciar todos os serviços"
    echo "  stop      - Parar todos os serviços"
    echo "  restart   - Reiniciar todos os serviços"
    echo "  logs      - Mostrar logs em tempo real"
    echo "  console   - Abrir Rails console"
    echo "  bash      - Abrir bash no container backend"
    echo "  migrate   - Executar migrações do banco"
    echo "  seed      - Executar seeds do banco"
    echo "  test      - Executar todos os testes"
    echo "  reset     - Resetar banco de dados"
    ;;
esac

---

# Comandos úteis para desenvolvimento

# Iniciar ambiente completo
docker-compose up -d

# Ver logs em tempo real
docker-compose logs -f

# Executar comando no backend
docker-compose exec backend01 rails console

# Executar testes
docker-compose exec backend01 bundle exec rspec
docker-compose exec frontend npm test

# Resetar banco de dados
docker-compose exec backend01 rails db:drop db:create db:migrate db:seed

# Parar todos os serviços
docker-compose down

# Rebuild containers
docker-compose build --no-cache

# Ver status dos containers
docker-compose ps