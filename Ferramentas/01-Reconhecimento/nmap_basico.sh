#!/bin/bash

# ==============================================================================
# Título:       nmap_basico.sh
# Descrição:    Realiza um reconhecimento inicial (ping sweep e port scan) no alvo.
# Autor:        Alexandre Vieira de Souza
# Data:         2025-12-11
# Versão:       1.0
# Uso:          ./nmap_basico.sh <IP_ALVO> <DIRETÓRIO>
# Notas:        Requer 'nmap' e 'ping' instalados.
# ==============================================================================
# LICENÇA (GPLv2):
#
# Este programa é software livre; você pode redistribuí-lo e/ou modificá-lo
# sob os termos da Licença Pública Geral GNU conforme publicada pela
# Free Software Foundation; tanto a versão 2 da Licença, como (a seu critério)
# qualquer versão posterior.
#
# Este programa é distribuído na expectativa de que seja útil,
# porém, SEM NENHUMA GARANTIA; nem mesmo a garantia implícita de
# COMERCIABILIDADE ou ADEQUAÇÃO A UMA FINALIDADE ESPECÍFICA.
# Consulte a Licença Pública Geral do GNU para mais detalhes.
# ==============================================================================

set -euo pipefail

# --- Código começa aqui ---
# Verifica se o IP foi fornecido
if [ $# -ne 1 ]; then
    echo "Uso: $0 <DIRETORIO_SALVAR_VARREDURA> <IP_ALVO>"
    exit 1
fi

ALVO=$1
DATA=$(date +%Y%m%d_%H%M%S)
DIRETORIO="scan_$ALVO"

# Cria diretório para resultados
mkdir -p $DIRETORIO

echo "[+] Iniciando varredura Nmap em $ALVO"
echo "[+] Resultados serão salvos em $DIRETORIO/"

# Varredura básica de portas comuns
nmap -sV -sC -p 21,22,23,25,53,80,443,445,3389,8080 -oN $DIRETORIO/scan_basico.txt $ALVO

echo "[+] Varredura concluída!"
echo "[+] Resultados salvos em $DIRETORIO/scan_basico.txt"