#!/bin/bash

[ -f ./common.sh ] && source ./common.sh || { RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'; }

SELECTED_SERVICES=$@

echo -e "${GREEN}=== INICIANDO DESPLIEGUE SELECTIVO ===${NC}\n"

if [ -z "$SELECTED_SERVICES" ]; then
    echo -e "${RED}[!] No se seleccionó ningún servicio.${NC}"
    exit 1
fi

if [[ "$SELECTED_SERVICES" == "--all" ]]; then
    SELECTED_SERVICES="Caddy Mantis SonarQube Jenkins GitLab_Runner"
fi

if [[ $SELECTED_SERVICES =~ "Caddy" ]]; then
    echo -e -n "${YELLOW}Introduce tu dominio (ej: sideral.com): ${NC}"
    read DOMAIN
    echo -e -n "${YELLOW}Introduce tu correo: ${NC}"
    read EMAIL
    
    CADDY_FILE="../docker/Caddy/Caddyfile"
    sed -i "s/example.com/$DOMAIN/g" "$CADDY_FILE"
    sed -i "s/tu-correo@example.com/$EMAIL/g" "$CADDY_FILE"
    echo -e "${GREEN}[+] Caddyfile configurado correctamente.${NC}"
fi

docker network create proxy_net 2>/dev/null

for SERVICE in $SELECTED_SERVICES; do
    echo -e "\n${BLUE}[*] Desplegando $SERVICE...${NC}"
    cd "../docker/$SERVICE" && docker compose up -d
    cd ../../scripts
done

echo -e "\n${GREEN}=== Despliegue finalizado ===${NC}"