<div align="center">
  <h1>CodeBspwm v2.0</h1>
  <p><b>Configuración de BSPWM para Kali Linux</b></p>
  <br>

  [![Versión](https://img.shields.io/badge/versión-2.0-0052cc.svg?style=for-the-badge)](https://github.com/CodeBreakCyber/CodeBspwm/releases)
  [![Licencia](https://img.shields.io/badge/licencia-MIT-success.svg?style=for-the-badge)](LICENSE)
  [![Estado Build](https://img.shields.io/badge/build-estable-success.svg?style=for-the-badge)](https://github.com/CodeBreakCyber/CodeBspwm/actions)
  [![Plataforma](https://img.shields.io/badge/Kali%20Linux-Rolling-557C94?style=for-the-badge&logo=kali-linux&logoColor=white)](https://www.kali.org/)
</div>

---

## 1. Descripción

**CodeBspwm** es una configuración ligera y funcional para el gestor de ventanas BSPWM en Kali Linux. 

---

## 2. Componentes

*   **BSPWM**: Gestor de ventanas tipo mosaico (Tiling).
*   **SXHKD**: Gestor de atajos de teclado.
*   **Kitty**: Terminal rápida acelerada por GPU.
*   **Picom**: Compositor para transparencias y animaciones suaves.
*   **Polybar**: Barra de estado minimalista.
*   **Rofi**: Lanzador de aplicaciones.

---

## 3. Instalación

```bash
git clone https://github.com/CodeBreakCyber/CodeBspwm
cd CodeBspwm
chmod +x install.sh
./install.sh
```

---

## 4. Atajos de Teclado 

Tecla principal: **Super** (Windows).

### 🪟 Ventanas
| Teclas | Acción |
| :--- | :--- |
| `Super + W` | Cerrar ventana. |
| `Super + Alt + W` | Cambiar Wallpaper. |
| `Super + G` | Intercambiar con ventana más grande. |
| `Super + S` | Modo Flotante (Floating). |
| `Super + T` | Modo Mosaico (Tiled). |
| `Super + F` | Pantalla completa. |
| `Super + Espacio` | Cambiar diseño (Mosaico / Una sola ventana). |
| `Super + Shift + ↓` | **Minimizar** ventana. |
| `Super + Shift + ↑` | **Restaurar** ventana minimizada. |

### 🧭 Navegación
| Teclas | Acción |
| :--- | :--- |
| `Super + Flechas` | Moverse entre ventanas. |
| `Super + Shift + Flechas` | Mover la ventana de lugar (Swap). |
| `Super + 1-0` | Ir al escritorio 1-10. |
| `Super + Shift + 1-0` | Enviar ventana al escritorio 1-10. |
| `Super + Tab` | Volver al escritorio anterior. |

### 🚀 Aplicaciones
| Teclas | App |
| :--- | :--- |
| `Super + Enter` | **Terminal** (Kitty). |
| `Super + D` | **Menú** (Rofi). |
| `Super + Shift + F` | **Firefox**. |
| `Super + Shift + C` | **Caido**. |
| `Super + Shift + B` | **Burp Suite**. |

### ⚙️ Sistema
| Teclas | Acción |
| :--- | :--- |
| `Super + L` | Bloquear pantalla. |
| `Super + Alt + R` | Reiniciar BSPWM (Recargar cambios). |
| `Super + Esc` | Recargar Teclas. |
| `Print` | Captura de pantalla. |

---

<div align="center">
  <p><b>Por CodeBreakCyber</b></p>
  <p>Licencia MIT</p>
</div>
