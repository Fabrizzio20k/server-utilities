#!/bin/bash

source ./common.sh

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    fi

    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    tee /etc/apt/sources.list.d/docker.sources <<EOF > /dev/null
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

configure_docker_group() {
    for USERNAME in $(awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd); do
        if ! groups "$USERNAME" 2>/dev/null | grep -q "\bdocker\b"; then
            usermod -aG docker "$USERNAME"
        fi
    done
    systemctl enable docker >/dev/null 2>&1
    systemctl restart docker >/dev/null 2>&1
}

install_zsh_starship() {
    local PKGS=""
    for pkg in zsh curl zoxide zsh-autosuggestions zsh-syntax-highlighting; do
        if ! dpkg -l | grep -qw "$pkg"; then
            PKGS="$PKGS $pkg"
        fi
    done
    
    if [ -n "$PKGS" ]; then
        apt-get install -y $PKGS
    fi

    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    ZSH_RC_BLOCK='
# Starship
eval "$(starship init zsh)"

# Zoxide (reemplazo moderno de z)
eval "$(zoxide init zsh)"
alias z="zoxide"

# Plugins de Zsh (Autosuggestions y Syntax Highlighting)
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
'

    for USER_HOME in /home/*; do
        if [ -d "$USER_HOME" ]; then
            USERNAME=$(basename "$USER_HOME")
            
            if ! awk -F: -v user="$USERNAME" '$1 == user {print $7}' /etc/passwd | grep -q "zsh"; then
                chsh -s $(which zsh) "$USERNAME"
            fi
            
            if [ ! -f "$USER_HOME/.zshrc" ]; then
                touch "$USER_HOME/.zshrc"
                chown "$USERNAME":"$USERNAME" "$USER_HOME/.zshrc"
            fi
            
            if ! grep -q "starship init zsh" "$USER_HOME/.zshrc"; then
                echo "$ZSH_RC_BLOCK" >> "$USER_HOME/.zshrc"
            fi
        fi
    done

    if ! awk -F: '$1 == "root" {print $7}' /etc/passwd | grep -q "zsh"; then
        chsh -s $(which zsh) root
    fi
    if [ ! -f "/root/.zshrc" ]; then touch "/root/.zshrc"; fi
    if ! grep -q "starship init zsh" "/root/.zshrc"; then
        echo "$ZSH_RC_BLOCK" >> "/root/.zshrc"
    fi
}

echo -e "${GREEN}=== INSTALACIÓN DE UTILIDADES DEL SISTEMA ===${NC}\n"

echo -e "${BLUE}--- ACTUALIZACIÓN DEL SISTEMA ---${NC}"
run_task "Actualizando lista de paquetes" apt-get update
run_task "Actualizando paquetes instalados" apt-get upgrade -y

echo -e "\n${BLUE}--- HERRAMIENTAS BASE Y NEOVIM ---${NC}"
if ! command -v git >/dev/null || ! command -v tmux >/dev/null || ! command -v btop >/dev/null || ! command -v jq >/dev/null || ! command -v tree >/dev/null || ! command -v unzip >/dev/null; then
    run_task "Instalando Git, Tmux, Btop, Jq, Tree y Unzip" apt-get install -y git tmux btop jq tree unzip
else
    echo -e "${GREEN}[+] Herramientas base ya instaladas.${NC}"
fi

if ! command -v nvim >/dev/null 2>&1; then
    run_task "Instalando Neovim" apt-get install -y neovim
else
    echo -e "${GREEN}[+] Neovim ya está instalado.${NC}"
fi

echo -e "\n${BLUE}--- INSTALACIÓN DE SHELL (ZSH, STARSHIP, ZOXIDE Y PLUGINS) ---${NC}"
run_task "Verificando e instalando Zsh, Starship y extensiones" install_zsh_starship

echo -e "\n${BLUE}--- INSTALACIÓN DE DOCKER ---${NC}"
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Docker ya está instalado.${NC}"
else
    run_task "Configurando repositorios e instalando Docker" install_docker
fi
run_task "Verificando y configurando permisos de Docker para usuarios" configure_docker_group

echo -e "\n${GREEN}=== ¡UTILIDADES INSTALADAS Y VERIFICADAS CON ÉXITO! ===${NC}"
echo -e "${YELLOW}Nota 1: Para ver los íconos de Starship, asegúrate de tener una Nerd Font instalada en la terminal de TU COMPUTADORA.${NC}"
echo -e "${YELLOW}Nota 2: Para que los cambios de Zsh y Docker apliquen, cierra tu sesión SSH y vuelve a entrar.${NC}"