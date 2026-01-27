# Stage 1: Build the React Application
FROM node:20-alpine as build

WORKDIR /app

# Copy package files first to leverage caching
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Copy source code
COPY frontend/ .

# Build the app (Vite)
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=build /app/dist /usr/share/nginx/html

# Reset default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config for frontend only
COPY infrastructure/nginx/frontend.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
