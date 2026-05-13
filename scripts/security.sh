#!/bin/bash

source ./common.sh

echo -e "${GREEN}=== CONFIGURACIÓN SEGURA DE SERVIDOR ===${NC}"

CONFIG_FILE="firewall.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}[!] No se encontró $CONFIG_FILE. Creando uno por defecto...${NC}"
    echo 'IN_PORTS=("22" "80" "443" "19999")' > "$CONFIG_FILE"
    echo 'OUT_PORTS=("any")' >> "$CONFIG_FILE"
fi
source "$CONFIG_FILE"

echo -e "\n${BLUE}--- GESTIÓN DE USUARIOS ---${NC}"
echo -e "${YELLOW}Verificando usuarios actuales en el sistema...${NC}"

awk -F':' '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read -r user; do
    if groups "$user" 2>/dev/null | grep -q "\bsudo\b"; then
        if [ ! -f "/etc/sudoers.d/$user" ] || ! grep -q "NOPASSWD:ALL" "/etc/sudoers.d/$user"; then
            echo -e "- $user ${GREEN}(sudo)${NC} -> ${YELLOW}Aplicando NOPASSWD...${NC}"
            echo "$user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$user"
            chmod 440 "/etc/sudoers.d/$user"
        else
            echo -e "- $user ${GREEN}(sudo)${NC} -> ${GREEN}[+] NOPASSWD ya configurado.${NC}"
        fi
    else
        echo -e "- $user ${RED}(normal)${NC}"
    fi
done

while true; do
    echo -e -n "\n${YELLOW}¿Deseas crear un nuevo usuario? (s/n): ${NC}"
    read ADD_NEW
    if [[ "$ADD_NEW" != "s" && "$ADD_NEW" != "S" ]]; then
        break
    fi

    echo -e -n "${YELLOW}Nombre del nuevo usuario: ${NC}"
    read NEW_USER
    
    if id "$NEW_USER" &>/dev/null; then
        echo -e "${RED}[!] El usuario $NEW_USER ya existe. Por favor, elige otro nombre.${NC}"
        continue
    fi

    echo -e -n "${YELLOW}¿Será administrador (sudo)? (s/n): ${NC}"
    read IS_SUDO
    
    echo -e "${BLUE}Si no tienes una llave SSH, abre otra terminal en tu PC y ejecuta: ${GREEN}ssh-keygen -t ed25519${NC}"
    echo -e -n "${YELLOW}Pega la llave pública SSH (ssh-...): ${NC}"
    read SSH_KEY

    useradd -m -s /bin/bash "$NEW_USER"

    if [[ "$IS_SUDO" == "s" || "$IS_SUDO" == "S" ]]; then
        usermod -aG sudo "$NEW_USER"
        echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$NEW_USER"
        chmod 440 /etc/sudoers.d/"$NEW_USER"
    fi

    mkdir -p /home/"$NEW_USER"/.ssh
    echo "$SSH_KEY" > /home/"$NEW_USER"/.ssh/authorized_keys
    chmod 700 /home/"$NEW_USER"/.ssh
    chmod 600 /home/"$NEW_USER"/.ssh/authorized_keys
    chown -R "$NEW_USER":"$NEW_USER" /home/"$NEW_USER"/.ssh

    echo -e "${GREEN}[+] Usuario $NEW_USER configurado con éxito.${NC}"
done

echo -e "\n${BLUE}--- ENDURECIMIENTO SSH ---${NC}"
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config && grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}[+] El endurecimiento de SSH ya está configurado.${NC}"
else
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${GREEN}[+] Autenticación por contraseña y login root deshabilitados.${NC}"
fi

echo -e "\n${BLUE}--- INSTALACIÓN DE PAQUETES ---${NC}"
run_task "Actualizando repositorios" apt-get update
run_task "Instalando dependencias base" apt-get install -y ufw curl wget gnupg lsb-release

echo -e "\n${BLUE}--- CONFIGURACIÓN DE FIREWALL (UFW) ---${NC}"
if ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}[+] UFW ya está activo. Verificando reglas...${NC}"
    for port in "${IN_PORTS[@]}"; do
        ufw allow "$port" > /dev/null 2>&1
    done
else
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    for port in "${IN_PORTS[@]}"; do
        ufw allow "$port" > /dev/null 2>&1
    done
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}[+] UFW configurado y habilitado leyendo $CONFIG_FILE.${NC}"
fi

echo -e "\n${BLUE}--- INSTALACIÓN DE CROWDSEC ---${NC}"
if command -v cscli >/dev/null 2>&1; then
    echo -e "${GREEN}[+] CrowdSec ya está instalado.${NC}"
else
    run_task "Añadiendo repositorio CrowdSec" bash -c "curl -s https://install.crowdsec.net | sh"
    run_task "Instalando CrowdSec y Bouncer" apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables
    systemctl enable crowdsec > /dev/null 2>&1
    systemctl restart crowdsec > /dev/null 2>&1
fi

echo -e "\n${BLUE}--- INSTALACIÓN DE NETDATA ---${NC}"
if command -v netdata >/dev/null 2>&1 || systemctl is-active --quiet netdata; then
    echo -e "${GREEN}[+] Netdata ya está instalado.${NC}"
else
    run_task "Descargando script de Netdata" wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
    run_task "Instalando Netdata" bash /tmp/netdata-kickstart.sh --non-interactive
    systemctl enable netdata > /dev/null 2>&1
    systemctl restart netdata > /dev/null 2>&1
fi

echo -e "\n${GREEN}=== ¡CONFIGURACIÓN COMPLETADA! ===${NC}"
echo -e "${YELLOW}IMPORTANTE: No cierres tu sesión actual. Prueba ingresar en otra terminal con tu nuevo usuario y llave SSH para confirmar el acceso.${NC}"