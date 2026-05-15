#!/bin/bash

[ -f ./common.sh ] && source ./common.sh || { RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'; }

SELECTED_SERVICES=$@
CADDY_FILE="../docker/Caddy/Caddyfile"

echo -e "${GREEN}=== INICIANDO DESPLIEGUE SELECTIVO ===${NC}\n"

if [ -z "$SELECTED_SERVICES" ]; then
    echo -e "${RED}[!] No se seleccionó ningún servicio.${NC}"
    exit 1
fi

if [[ "$SELECTED_SERVICES" == "--all" ]]; then
    SELECTED_SERVICES="Caddy MantisBT SonarQube Jenkins Gitlab-Runner Redis Minio"
fi

NEEDS_CONFIG=false
if grep -q "example.com" "$CADDY_FILE" 2>/dev/null; then
    if [[ $SELECTED_SERVICES =~ "Caddy" ]] || [[ $SELECTED_SERVICES =~ "Minio" ]] || [[ $SELECTED_SERVICES =~ "Redis" ]]; then
        NEEDS_CONFIG=true
    fi
fi

if [ "$NEEDS_CONFIG" = true ]; then
    echo -e -n "${YELLOW}Introduce tu dominio base (ej: sideral.com): ${NC}"
    read DOMAIN
    if [ -z "$DOMAIN" ]; then echo -e "${RED}Error: El dominio es obligatorio.${NC}"; exit 1; fi
fi

if [[ $SELECTED_SERVICES =~ "Minio" ]]; then
    LICENSE_FILE="../docker/Minio/minio.license"
    if [ ! -f "$LICENSE_FILE" ]; then
        echo -e "${RED}[!] Error: No se encontró la licencia en $LICENSE_FILE${NC}"
        exit 1
    fi
    
    if grep -q "minio-console.example.com" "$CADDY_FILE"; then
        sed -i "s/minio-console.example.com/minio.$DOMAIN/g" "$CADDY_FILE"
        sed -i "s/minio.example.com/s3.$DOMAIN/g" "$CADDY_FILE"
        echo -e "${GREEN}[+] Subdominios de MinIO configurados.${NC}"
    fi
fi

if [[ $SELECTED_SERVICES =~ "Redis" ]]; then
    if grep -q "redis.example.com" "$CADDY_FILE"; then
        sed -i "s/redis.example.com/redis.$DOMAIN/g" "$CADDY_FILE"
        echo -e "${GREEN}[+] Subdominio de Redis configurado.${NC}"
    fi
fi

if [[ $SELECTED_SERVICES =~ "Caddy" ]]; then
    if grep -q "example.com" "$CADDY_FILE"; then
        echo -e -n "${YELLOW}Introduce tu correo para SSL: ${NC}"
        read EMAIL
        
        sed -i "s/example.com/$DOMAIN/g" "$CADDY_FILE"
        sed -i "s/tu-correo@example.com/$EMAIL/g" "$CADDY_FILE"
        echo -e "${GREEN}[+] Caddyfile configurado para el dominio base $DOMAIN.${NC}"
    else
        echo -e "${GREEN}[+] Caddyfile ya estaba configurado previamente.${NC}"
    fi
fi

if ! docker network ls | grep -q "proxy_net"; then
    docker network create proxy_net >/dev/null 2>&1
    echo -e "${GREEN}[+] Red 'proxy_net' creada.${NC}"
fi

for SERVICE in $SELECTED_SERVICES; do
    if [ -d "../docker/$SERVICE" ]; then
        echo -e "\n${BLUE}[*] Verificando $SERVICE...${NC}"
        cd "../docker/$SERVICE"
        
        if docker compose ps --services --filter "status=running" 2>/dev/null | grep -q .; then
            echo -e "${GREEN}[+] Los contenedores de $SERVICE ya están en ejecución.${NC}"
        else
            echo -e "${YELLOW}[*] Desplegando $SERVICE...${NC}"
            docker compose up -d
        fi
        cd ../../scripts
    else
        echo -e "${RED}[!] Error: La carpeta ../docker/$SERVICE no existe.${NC}"
    fi
done

echo -e "\n${YELLOW}====================================================${NC}"
echo -e "${YELLOW}        ¡DESPLIEGUE COMPLETADO CON ÉXITO!        ${NC}"
echo -e "${YELLOW}====================================================${NC}"

if [[ $SELECTED_SERVICES =~ "MantisBT" ]]; then
    echo -e "${BLUE}[!] MANTISBT:${NC}"
    echo -e "    - Entra a la interfaz web y configura el correo (SMTP)."
    echo -e "    - Recuerda desactivar el usuario 'admin' o cambiar su clave."
fi

if [[ $SELECTED_SERVICES =~ "Minio" ]]; then
    echo -e "${BLUE}[!] MINIO:${NC}"
    echo -e "    - El script ya actualizó el dominio en el compose.yaml."
    echo -e "    - Si las redirecciones fallan, verifica las variables"
    echo -e "      MINIO_BROWSER_REDIRECT_URL y MINIO_SERVER_URL."
fi

if [[ $SELECTED_SERVICES =~ "Caddy" ]]; then
    echo -e "${BLUE}[!] CADDY:${NC}"
    echo -e "    - Verifica los certificados SSL con: 'docker logs caddy_proxy'."
fi

echo -e "${YELLOW}====================================================${NC}"