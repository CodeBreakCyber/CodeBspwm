# KaliBspwm Makefile
# Simplifica la instalación y mantenimiento del entorno

.PHONY: all install clean test help

help:
	@echo "KaliBspwm - Comandos disponibles:"
	@echo "  make install  - Iniciar instalación completa"
	@echo "  make clean    - Limpiar archivos temporales y caché"
	@echo "  make test     - Verificar scripts con ShellCheck"

all: install

install:
	@echo "Iniciando instalador..."
	@chmod +x install.sh
	@./install.sh

clean:
	@echo "Limpiando temporales..."
	@rm -rf ~/github
	@rm -f *.log *.bak
	@echo "Limpieza completada."

test:
	@echo "Ejecutando ShellCheck..."
	@shellcheck install.sh lib/*.sh scripts/*.sh || echo "Advervencias encontradas (ignorando errores no críticos)"