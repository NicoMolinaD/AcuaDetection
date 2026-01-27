#!/bin/bash

#  Quick Reference - Comandos Útiles para Malcom SSL

echo " Malcom SSL/TLS - Quick Reference"
echo "===================================="
echo ""
echo "📍 Antes de empezar:"
echo "   1. Ejecuta: ./setup_ssl.sh"
echo "   2. Lee: SSL_TLS_SETUP.md"
echo ""

case "$1" in

  start)
    echo " Iniciando aplicación..."
    docker-compose up -d
    echo "✓ Esperando 15 segundos para que se generen certificados..."
    sleep 15
    echo "✓ Aplicación iniciada"
    echo "📍 Accede a: https://malcom.local"
    ;;

  stop)
    echo "🛑 Deteniendo aplicación..."
    docker-compose down
    echo "✓ Detenido"
    ;;

  logs)
    echo "📜 Mostrando logs de Nginx..."
    docker-compose logs -f nginx
    ;;

  logs-backend)
    echo "📜 Mostrando logs del Backend..."
    docker-compose logs -f backend
    ;;

  status)
    echo " Estado de servicios:"
    docker-compose ps
    ;;

  cert-check)
    echo " Información de certificado:"
    docker exec malcom_nginx openssl x509 -in /etc/letsencrypt/live/malcom.local/fullchain.pem -text -noout | grep -A 2 "Not Before\|Not After"
    ;;

  cert-renew)
    echo "🔄 Renovando certificados..."
    docker exec malcom_nginx certbot renew
    docker exec malcom_nginx nginx -s reload
    echo "✓ Certificados renovados"
    ;;

  test-https)
    echo "🧪 Probando conexión HTTPS..."
    curl -k -v https://malcom.local/ 2>&1 | head -20
    ;;

  test-http-redirect)
    echo "🧪 Probando redirección HTTP → HTTPS..."
    curl -I http://malcom.local/
    ;;

  test-ip-block)
    echo "🧪 Probando bloqueo de IP (desde otra IP)..."
    echo "[WARN]  Este test solo funciona desde una IP diferente a 10.3.11.101"
    curl -k https://192.168.1.1/ 2>&1
    ;;

  nginx-reload)
    echo "♻️  Recargando Nginx (sin parar)..."
    docker exec malcom_nginx nginx -s reload
    echo "✓ Nginx recargado"
    ;;

  nginx-test)
    echo " Validando configuración de Nginx..."
    docker exec malcom_nginx nginx -t
    ;;

  clean)
    echo "🧹 Limpiando todo (incluyendo volúmenes y datos)..."
    read -p "¿Estás seguro? [s/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
      docker-compose down -v
      echo "✓ Limpieza completada"
    fi
    ;;

  help|--help|-h|"")
    echo "Comandos disponibles:"
    echo ""
    echo "  ./malcom_ssl.sh start              - Iniciar aplicación"
    echo "  ./malcom_ssl.sh stop               - Detener aplicación"
    echo "  ./malcom_ssl.sh status             - Ver estado de servicios"
    echo "  ./malcom_ssl.sh logs               - Ver logs de Nginx"
    echo "  ./malcom_ssl.sh logs-backend       - Ver logs del Backend"
    echo ""
    echo "  ./malcom_ssl.sh cert-check         - Ver info del certificado"
    echo "  ./malcom_ssl.sh cert-renew         - Renovar certificados"
    echo ""
    echo "  ./malcom_ssl.sh test-https         - Probar HTTPS"
    echo "  ./malcom_ssl.sh test-http-redirect - Probar redirección HTTP"
    echo "  ./malcom_ssl.sh test-ip-block      - Probar bloqueo de IP"
    echo ""
    echo "  ./malcom_ssl.sh nginx-reload       - Recargar Nginx"
    echo "  ./malcom_ssl.sh nginx-test         - Validar configuración"
    echo ""
    echo "  ./malcom_ssl.sh clean              - Limpiar todo"
    echo "  ./malcom_ssl.sh help               - Esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./malcom_ssl.sh start"
    echo "  ./malcom_ssl.sh logs"
    echo "  ./malcom_ssl.sh cert-check"
    ;;

  *)
    echo "[FAILED] Comando no reconocido: $1"
    echo "Ejecuta: ./malcom_ssl.sh help"
    exit 1
    ;;

esac
