# Etapa 1: compilación del Frontend React/Vite
FROM node:20-alpine AS build
WORKDIR /workspace

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Etapa 2: servidor Nginx con usuario no root
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /workspace/dist /usr/share/nginx/html

EXPOSE 8080
