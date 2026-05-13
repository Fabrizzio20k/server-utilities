#!/bin/bash

source ./common.sh

install_docker() {
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
        usermod -aG docker "$USERNAME"
    done
    systemctl enable docker
    systemctl restart docker
}

install_zsh_starship() {
    apt-get install -y zsh curl zoxide zsh-autosuggestions zsh-syntax-highlighting
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
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
            chsh -s $(which zsh) "$USERNAME"
            
            if [ ! -f "$USER_HOME/.zshrc" ]; then
                touch "$USER_HOME/.zshrc"
                chown "$USERNAME":"$USERNAME" "$USER_HOME/.zshrc"
            fi
            
            if ! grep -q "starship init zsh" "$USER_HOME/.zshrc"; then
                echo "$ZSH_RC_BLOCK" >> "$USER_HOME/.zshrc"
            fi
        fi
    done

    chsh -s $(which zsh) root
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
run_task "Instalando Git, Tmux, Btop, Jq, Tree y Unzip" apt-get install -y git tmux btop jq tree unzip
run_task "Instalando Neovim" apt-get install -y neovim

echo -e "\n${BLUE}--- INSTALACIÓN DE SHELL (ZSH, STARSHIP, ZOXIDE Y PLUGINS) ---${NC}"
run_task "Instalando Zsh, Starship y extensiones" install_zsh_starship

echo -e "\n${BLUE}--- INSTALACIÓN DE DOCKER ---${NC}"
run_task "Configurando repositorios e instalando Docker" install_docker
run_task "Configurando permisos de Docker para usuarios" configure_docker_group

echo -e "\n${GREEN}=== ¡UTILIDADES INSTALADAS CON ÉXITO! ===${NC}"
echo -e "${YELLOW}Nota 1: Para ver los íconos de Starship, asegúrate de tener una Nerd Font instalada en la terminal de TU COMPUTADORA.${NC}"
echo -e "${YELLOW}Nota 2: Para que los cambios de Zsh y Docker apliquen, cierra tu sesión SSH y vuelve a entrar.${NC}"