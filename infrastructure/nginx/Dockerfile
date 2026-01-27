FROM nginx:alpine

# Instalar CertBot y dependencias
RUN apk add --no-cache certbot certbot-nginx python3 py3-pip curl bash openssl

# Crear directorios necesarios
RUN mkdir -p /var/www/certbot /var/www/html
RUN mkdir -p /etc/nginx/conf.d

# Copiar script de inicio
COPY init_certbot.sh /usr/local/bin/init_certbot.sh
RUN chmod +x /usr/local/bin/init_certbot.sh

# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Crear un script para renovación automática de certificados
COPY renew_certs.sh /usr/local/bin/renew_certs.sh
RUN chmod +x /usr/local/bin/renew_certs.sh

# Exponer puertos
EXPOSE 80 443

# Comando de inicio - Usar bash directamente sin entrypoint de nginx
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "/usr/local/bin/init_certbot.sh"]
