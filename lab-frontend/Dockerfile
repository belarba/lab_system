# Dockerfile para Lab Frontend (React + Vite)

# Estágio 1: Build da aplicação
FROM node:20-alpine AS builder

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY package.json package-lock.json* ./

# Instalar dependências (incluindo devDependencies para o build)
RUN npm ci && npm cache clean --force

# Copiar código fonte
COPY . .

# Definir variáveis de ambiente para build
ARG VITE_API_BASE_URL=http://localhost:3000
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

ARG VITE_APP_NAME="Lab System"
ENV VITE_APP_NAME=$VITE_APP_NAME

ARG VITE_APP_VERSION="1.0.0"
ENV VITE_APP_VERSION=$VITE_APP_VERSION

# Build da aplicação
RUN npm run build

# Estágio 2: Servir aplicação com Nginx
FROM nginx:alpine AS production

# Instalar curl para health checks
RUN apk add --no-cache curl

# Criar configuração básica do nginx inline para SPA
RUN echo 'events { worker_connections 1024; } \
http { \
    include /etc/nginx/mime.types; \
    default_type application/octet-stream; \
    sendfile on; \
    gzip on; \
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript; \
    server { \
        listen 80; \
        server_name _; \
        root /usr/share/nginx/html; \
        index index.html; \
        location / { \
            try_files $uri $uri/ /index.html; \
        } \
        location /health { \
            return 200 "healthy\\n"; \
            add_header Content-Type text/plain; \
        } \
        location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
            expires 1y; \
            add_header Cache-Control "public, immutable"; \
        } \
    } \
}' > /etc/nginx/nginx.conf

# Copiar arquivos buildados do estágio anterior
COPY --from=builder /app/dist /usr/share/nginx/html

# Expor portas (80 para frontend, 9999 para API se usando configuração integrada)
EXPOSE 80
EXPOSE 9999

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Labels para metadados
LABEL maintainer="Lab System Team"
LABEL description="Lab System Frontend - React Application"
LABEL version="1.0.0"

# Comando padrão (o nginx:alpine já define o CMD adequado)