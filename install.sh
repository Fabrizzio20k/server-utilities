#!/bin/bash

source ./scripts/common.sh

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Por favor, ejecuta este script como root (sudo bash install.sh)${NC}"
    exit 1
fi

show_menu() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
 ____                           _ _   _ _ _ _   _           
/ ___|  ___ _ ____   _____ _ __| | | | |_(_) (_) |_(_) ___  ___ 
\___ \ / _ \ '__\ \ / / _ \ '__| | | | __| | | | __| |/ _ \/ __|
 ___) |  __/ |   \ V /  __/ |  | |_| | |_| | | | |_| |  __/\__ \
|____/ \___|_|    \_/ \___|_|   \___/ \__|_|_|_|\__|_|\___||___/
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}       By: Fabrizzio20k | https://github.com/Fabrizzio20k${NC}\n"

    echo -e "${GREEN}1.${NC} Instalación de Seguridad y Utilidades (Paso a Paso)"
    echo -e "${GREEN}2.${NC} Instalación Express (Todo de golpe)"
    echo -e "${GREEN}3.${NC} Desplegar Servicios Docker (Caddy, Jenkins, Sonar, etc.)"
    echo -e "${GREEN}4.${NC} Salir\n"
    
    echo -e -n "${BLUE}Elige una opción [1-4]: ${NC}"
}

deploy_docker_menu() {
    echo -e "\n${BLUE}--- CONFIGURACIÓN DE SERVICIOS DOCKER ---${NC}"
    echo -e "1) Instalar TODOS los servicios"
    echo -e "2) Seleccionar servicios específicos"
    echo -e "3) Volver al menú principal"
    echo -e -n "\n${YELLOW}Opción: ${NC}"
    read DOCKER_OPT

    case $DOCKER_OPT in
        1)
            (cd scripts && bash tools.sh --all)
            ;;
        2)
            echo -e "\n${YELLOW}Responde 's' para instalar o 'n' para saltar:${NC}"
            SERVICES=""
            for s in Caddy Mantis SonarQube Jenkins GitLab_Runner Redis MinIO; do
                echo -e -n "¿Instalar ${BLUE}$s${NC}? (s/n): "
                read RESP
                if [[ "$RESP" =~ ^[sS]$ ]]; then
                    SERVICES="$SERVICES $s"
                fi
            done
            
            if [ -n "$SERVICES" ]; then
                (cd scripts && bash tools.sh $SERVICES)
            else
                echo -e "${YELLOW}[!] No se seleccionó ningún servicio para instalar.${NC}"
            fi
            ;;
        *)
            return
            ;;
    esac
}

while true; do
    show_menu
    read OPTION
    case $OPTION in
        1)
            echo -e "\n${BLUE}[*] Iniciando instalación paso a paso...${NC}"
            echo -e -n "\n${YELLOW}¿Ejecutar security.sh? (s/n): ${NC}"
            read R_SEC; [[ "$R_SEC" =~ ^[sS]$ ]] && (cd scripts && bash security.sh)
            
            echo -e -n "\n${YELLOW}¿Ejecutar utilities.sh? (s/n): ${NC}"
            read R_UTL; [[ "$R_UTL" =~ ^[sS]$ ]] && (cd scripts && bash utilities.sh)
            
            echo -e "\n${GREEN}[+] Proceso paso a paso finalizado.${NC}"
            read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
            ;;
        2)
            (cd scripts && bash security.sh)
            (cd scripts && bash utilities.sh)
            (cd scripts && bash tools.sh --all)
            
            echo -e "\n${GREEN}[+] Instalación express finalizada.${NC}"
            read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
            ;;
        3) 
            deploy_docker_menu
            read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
            ;;
        4) 
            echo -e "${GREEN}¡Nos vemos, Fabrizzio!${NC}"
            exit 0 
            ;;
        *)
            echo -e "\n${RED}[!] Opción no válida.${NC}"
            sleep 1
            ;;
    esac
done