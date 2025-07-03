FROM node:20-alpine

# Instalar dependências do sistema
RUN apk add --no-cache curl bash

WORKDIR /app

# Configurar npm para ser mais robusto
RUN npm config set fetch-timeout 600000
RUN npm config set fetch-retry-mintimeout 10000
RUN npm config set fetch-retry-maxtimeout 60000

# Variáveis de ambiente
ENV NODE_ENV=development
ENV VITE_API_BASE_URL=http://localhost:9999
ENV CHOKIDAR_USEPOLLING=true

# Copiar arquivos de dependência
COPY package*.json ./

# Instalar dependências com retry
RUN npm ci --cache /tmp/.npm || npm ci --cache /tmp/.npm || npm ci --cache /tmp/.npm

# Copiar código
COPY . .

# Criar e dar permissões para cache do Vite
RUN mkdir -p /tmp/.vite && chmod 777 /tmp/.vite

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:5173/ || exit 1

EXPOSE 5173

# Comando com cache customizado
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
