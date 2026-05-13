# 🛠️ Server Utilities

**Automated Server Orchestration & Security Suite**

Este repositorio contiene un conjunto de herramientas para desplegar una infraestructura de ingeniería de software profesional, segura y automatizada sobre **Ubuntu 24.04 LTS**.

## 📂 Estructura del Proyecto

```text
/server-utilities
├── install.sh              # Menú maestro de orquestación
├── scripts/                # Scripts de configuración lógica
│   ├── security.sh         # Hardening, SSH, UFW y Fail2Ban
│   ├── utilities.sh        # Docker, Netdata y herramientas base
│   ├── tools.sh            # Despliegue selectivo de servicios Docker
│   └── firewall.conf       # ⚙️ Configuración de puertos permitidos
└── docker/                 # Directorios de servicios (Compose + Config)
    ├── Caddy/              # Proxy Inverso y SSL automático
    ├── Jenkins/            # CI/CD (Arquitectura Docker-in-Docker)
    ├── SonarQube/          # Análisis de calidad de código
    ├── Mantis/             # Gestión de tickets y bugs
    └── GitLab_Runner/      # Ejecutor de pipelines de GitLab

```

---

## 🚀 Inicio Rápido

Para iniciar la configuración del servidor, clona el repositorio y ejecuta el menú principal como root:

```bash
git clone https://github.com/Fabrizzio20k/server-utilities.git
cd server-utilities
sudo bash install.sh

```

---

## 🛡️ Gestión del Firewall

Para mantener el servidor blindado pero accesible, la gestión de puertos se centraliza en un solo archivo de configuración.

### ¿Dónde agregar puertos?

Edita el archivo `scripts/firewall.conf`. Este archivo es leído por `security.sh` para abrir los puertos necesarios en **UFW**.

**Formato de `scripts/firewall.conf`:**

```conf
IN_PORTS=(
    "22/tcp"
    "80/tcp"
    "443/tcp"
    "443/udp"
    "54320/tcp"
    "63790/tcp"
    "19999/tcp"
)

OUT_PORTS=("any")
```

> [!IMPORTANT]
> Después de modificar este archivo, vuelve a ejecutar la **Opción 1** del menú principal o lanza `bash scripts/security.sh` para aplicar las nuevas reglas.

---

## 🐳 Servicios Desplegados

El sistema utiliza **Caddy** como punto de entrada único. Todos los servicios están aislados en una red interna de Docker (`proxy_net`).

| Servicio | Subdominio Sugerido | Puerto Interno |
| --- | --- | --- |
| **Jenkins** | `jenkins.tu-dominio.com` | 8080 |
| **SonarQube** | `sonar.tu-dominio.com` | 9000 |
| **MantisBT** | `mantis.tu-dominio.com` | 80 |
| **Netdata** | `monitor.tu-dominio.com` | 19999 |

---

## 🛠️ Mantenimiento Común

### Ver logs de un servicio

Si un servicio no carga, revisa sus logs desde la carpeta correspondiente:

```bash
cd docker/Jenkins && docker compose logs -f

```

### Actualizar configuración de Caddy

Si agregas un nuevo servicio al `Caddyfile`, recárgalo sin detener los contenedores:

```bash
docker exec -it caddy_proxy caddy reload --config /etc/caddy/Caddyfile

```

---

**Desarrollado por:** [Fabrizzio20k](https://github.com/Fabrizzio20k)
**Licencia:** MIT | 2026
