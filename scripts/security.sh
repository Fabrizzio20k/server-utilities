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
while true; do
    echo -e -n "${YELLOW}Nombre del nuevo usuario: ${NC}"
    read NEW_USER
    
    echo -e -n "${YELLOW}¿Será administrador (sudo)? (s/n): ${NC}"
    read IS_SUDO
    
    echo -e "${BLUE} Si no tienes una llave SSH, abre otra terminal en tu PC y ejecuta: ${GREEN}ssh-keygen -t ed25519${NC}"
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

    echo -e "${GREEN}[+] Usuario $NEW_USER configurado con éxito.${NC}\n"
    
    echo -e -n "${YELLOW}¿Deseas añadir otro usuario? (s/n): ${NC}"
    read ADD_MORE
    if [[ "$ADD_MORE" != "s" && "$ADD_MORE" != "S" ]]; then
        break
    fi
done

echo -e "\n${BLUE}--- ENDURECIMIENTO SSH ---${NC}"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
echo -e "${GREEN}[+] Autenticación por contraseña y login root deshabilitados.${NC}"

echo -e "\n${BLUE}--- INSTALACIÓN DE PAQUETES ---${NC}"
run_task "Actualizando repositorios" apt-get update
run_task "Instalando dependencias base" apt-get install -y ufw curl wget gnupg lsb-release

echo -e "\n${BLUE}--- CONFIGURACIÓN DE FIREWALL (UFW) ---${NC}"
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1

for port in "${IN_PORTS[@]}"; do
    ufw allow "$port"
done

ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}[+] UFW configurado y habilitado leyendo $CONFIG_FILE.${NC}"

echo -e "\n${BLUE}--- INSTALACIÓN DE CROWDSEC ---${NC}"
run_task "Añadiendo repositorio CrowdSec" bash -c "curl -s https://install.crowdsec.net | sh"
run_task "Instalando CrowdSec y Bouncer" apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables
systemctl enable crowdsec > /dev/null 2>&1
systemctl restart crowdsec > /dev/null 2>&1

echo -e "\n${BLUE}--- INSTALACIÓN DE NETDATA ---${NC}"
run_task "Descargando script de Netdata" wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
run_task "Instalando Netdata" bash /tmp/netdata-kickstart.sh --non-interactive
systemctl enable netdata > /dev/null 2>&1
systemctl restart netdata > /dev/null 2>&1

echo -e "\n${GREEN}=== ¡CONFIGURACIÓN COMPLETADA! ===${NC}"
echo -e "${YELLOW}IMPORTANTE: No cierres tu sesión actual. Prueba ingresar en otra terminal con tu nuevo usuario y llave SSH para confirmar el acceso.${NC}"