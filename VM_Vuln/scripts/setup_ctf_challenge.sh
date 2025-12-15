#!/bin/bash
# Script de Configuração do Cenário CTF para OSCP Practice
# Nome: setup_ctf_challenge.sh
# Uso: sudo bash setup_ctf_challenge.sh

set -e  # Abortar em caso de erro

echo "🚀 Iniciando configuração do Cenário CTF 'Rede Interna Perigosa'"
echo "⚠️  Este script deve ser executado como root em uma VM Debian 12 limpa"

# 1. Atualizar sistema e instalar dependências
echo "🔧 Atualizando sistema e instalando pacotes..."
apt update && apt upgrade -y
apt install -y nginx python3-pip python3-venv redis-server curl git

# 2. Configurar usuário normal
echo "👤 Criando usuário para a flag..."
useradd -m -s /bin/bash ctfuser
echo "ctfuser:ctfuser123" | chpasswd
usermod -aG sudo ctfuser

# 3. Configurar Redis (serviço interno)
echo "⚙️  Configurando Redis como serviço interno..."
systemctl stop redis-server
cp /etc/redis/redis.conf /etc/redis/redis.conf.backup

cat > /etc/redis/redis.conf << 'EOF'
bind 127.0.0.1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16
always-show-logo no
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
requirepass ""
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

# Alterar permissões do diretório Redis
mkdir -p /var/lib/redis/.ssh
chown -R redis:redis /var/lib/redis
chmod 700 /var/lib/redis/.ssh

# Configurar serviço Redis
systemctl enable redis-server
systemctl start redis-server

# 4. Configurar aplicação web Flask
echo "🌐 Configurando aplicação web Flask com vulnerabilidade SSRF..."

# Criar diretório da aplicação
mkdir -p /var/www/internal-finder
cd /var/www/internal-finder

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências
pip install flask requests redis gunicorn

# Criar aplicação Flask vulnerável
cat > app.py << 'EOF'
import os
import requests
from flask import Flask, request, render_template_string, redirect, url_for
import urllib.parse
import re

app = Flask(__name__)

# Template HTML simples com formulário vulnerável a SSRF
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Internal Resource Finder</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #2c3e50; }
        .search-box { margin: 20px 0; }
        input[type="text"] { padding: 8px; width: 300px; }
        button { padding: 8px 16px; background: #3498db; color: white; border: none; cursor: pointer; }
        .result { margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px; }
        .error { color: #e74c3c; }
        .warning { background: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Internal Resource Finder</h1>
        <div class="warning">
            <strong>⚠️ Aviso:</strong> Esta ferramenta é para uso interno autorizado apenas. 
            Não utilize para acessar recursos não autorizados.
        </div>
        
        <div class="search-box">
            <form method="GET" action="/search">
                <input type="text" name="url" placeholder="Digite URL interna (ex: http://intranet/reports)" required>
                <button type="submit">Buscar</button>
            </form>
        </div>
        
        {% if error %}
        <div class="error">{{ error }}</div>
        {% endif %}
        
        {% if result %}
        <div class="result">
            <h3>Resultado da busca:</h3>
            <pre>{{ result }}</pre>
        </div>
        {% endif %}
        
        <div style="margin-top: 30px; padding: 15px; background: #e8f4f8; border-radius: 5px;">
            <h3>ℹ️ Informações do Sistema</h3>
            <p><strong>Hostname:</strong> {{ hostname }}</p>
            <p><strong>IP Address:</strong> {{ ip_address }}</p>
            <p><strong>Internal Services:</strong></p>
            <ul>
                <li>Redis Database (internal only): port 6379</li>
                <li>Internal API Gateway: port 8080 (restricted)</li>
                <li>File Storage Service: port 9000 (restricted)</li>
            </ul>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    import socket
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    return render_template_string(HTML_TEMPLATE, hostname=hostname, ip_address=ip_address)

@app.route('/search')
def search():
    url = request.args.get('url', '').strip()
    
    if not url:
        return redirect(url_for('index'))
    
    # VULNERABILIDADE SSRF: Validação insuficiente
    try:
        # Permitir apenas http/https, mas não filtra localhost ou IPs internos
        if not url.startswith(('http://', 'https://')):
            return render_template_string(HTML_TEMPLATE, 
                                        error="❌ URL deve começar com http:// ou https://", 
                                        hostname=request.host,
                                        ip_address=request.remote_addr)
        
        # Não bloquear localhost, 127.0.0.1, ou IPs internos
        parsed = urllib.parse.urlparse(url)
        hostname = parsed.hostname
        
        # Filtro muito permissivo (vulnerável)
        dangerous_hosts = ['127.0.0.1', 'localhost', '192.168', '10.', '172.16', '172.17', '172.18', '172.19', '172.20', '172.21', '172.22', '172.23', '172.24', '172.25', '172.26', '172.27', '172.28', '172.29', '172.30', '172.31']
        
        # Aviso, mas não bloqueia (simulando má implementação de segurança)
        if any(host in hostname for host in dangerous_hosts):
            warning = "⚠️ Aviso: Você está tentando acessar um recurso interno. Esta ação está sendo monitorada."
            # Mas continua a requisição!
        
        # Fazer requisição SSRF
        headers = {
            'User-Agent': 'Internal Resource Finder Bot/1.0',
            'Accept': '*/*'
        }
        
        response = requests.get(url, headers=headers, timeout=5)
        result = f"Status Code: {response.status_code}\n\nHeaders:\n{dict(response.headers)}\n\nContent:\n{response.text[:500]}..."  # Limitar output
        
        return render_template_string(HTML_TEMPLATE, result=result, hostname=request.host, ip_address=request.remote_addr)
    
    except requests.exceptions.RequestException as e:
        error_msg = f"❌ Erro ao buscar recurso: {str(e)}"
        return render_template_string(HTML_TEMPLATE, error=error_msg, hostname=request.host, ip_address=request.remote_addr)
    except Exception as e:
        error_msg = f"❌ Erro inesperado: {str(e)}"
        return render_template_string(HTML_TEMPLATE, error=error_msg, hostname=request.host, ip_address=request.remote_addr)

@app.route('/health')
def health():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
EOF

# Criar serviço systemd para a aplicação Flask
cat > /etc/systemd/system/internal-finder.service << 'EOF'
[Unit]
Description=Internal Resource Finder (Flask App)
After=network.target redis-server.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/internal-finder
Environment="PATH=/var/www/internal-finder/venv/bin"
ExecStart=/var/www/internal-finder/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configurar permissões
chown -R www-data:www-data /var/www/internal-finder
chmod -R 755 /var/www/internal-finder

# Recarregar systemd e iniciar serviço
systemctl daemon-reload
systemctl enable internal-finder
systemctl start internal-finder

# 5. Configurar Nginx como proxy reverso
echo "⚙️  Configurando Nginx como proxy reverso..."

cat > /etc/nginx/sites-available/internal-finder << 'EOF'
server {
    listen 80;
    server_name internal-network.local;
    server_name localhost;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
        
        proxy_buffering off;
        proxy_cache off;
    }

    location /static/ {
        alias /var/www/internal-finder/static/;
        expires 30d;
    }

    location /health {
        proxy_pass http://127.0.0.1:5000;
        access_log off;
    }

    # Bloquear acesso direto a serviços internos (mas SSRF ainda funciona)
    location ~* ^/(redis|memcached|internal|admin|api) {
        deny all;
        return 403;
    }
}
EOF

# Habilitar o site
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/internal-finder /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 6. Configurar SSH para usuário redis (para backdoor)
echo "🔑 Configurando acesso SSH para usuário redis..."

# Preparar diretório .ssh para redis
mkdir -p /var/lib/redis/.ssh
chown redis:redis /var/lib/redis/.ssh
chmod 700 /var/lib/redis/.ssh

# 7. Criar flags e configurar escalonamento de privilégios
echo "🚩 Criando flags e configurando escalonamento..."

# Criar flag user
mkdir -p /home/ctfuser/flags
echo "OSCP{ssrf_to_redis_access}" > /home/ctfuser/flags/user.txt
chown ctfuser:ctfuser /home/ctfuser/flags/user.txt
chmod 644 /home/ctfuser/flags/user.txt

# Criar flag root
mkdir -p /root/flags
echo "OSCP{redis_ssh_backdoor_pwned}" > /root/flags/root.txt
chmod 600 /root/flags/root.txt

# Criar script de backup vulnerável
cat > /usr/local/bin/backup_script.sh << 'EOF'
#!/bin/bash
# Script de backup automático (vulnerável)
# Este script é executado como root via cron e pode ser modificado

BACKUP_DIR="/var/backups/system"
LOG_FILE="/var/log/backup.log"

echo "[$(date)] Iniciando backup do sistema..." >> $LOG_FILE

# Backup de diretórios importantes
tar -czf $BACKUP_DIR/home_backup_$(date +%Y%m%d).tar.gz /home >> $LOG_FILE 2>&1
tar -czf $BACKUP_DIR/etc_backup_$(date +%Y%m%d).tar.gz /etc >> $LOG_FILE 2>&1

echo "[$(date)] Backup concluído com sucesso!" >> $LOG_FILE

# Vulnerabilidade: O script não valida o conteúdo do diretório
# Se um atacante conseguir escrever aqui, pode executar comandos
if [ -f /tmp/backup_commands.sh ]; then
    echo "[$(date)] Executando comandos de backup personalizados..." >> $LOG_FILE
    bash /tmp/backup_commands.sh >> $LOG_FILE 2>&1
fi
EOF

chmod +x /usr/local/bin/backup_script.sh
chown root:root /usr/local/bin/backup_script.sh

# Configurar sudoers para redis (sem senha para o script de backup)
echo "redis ALL=(ALL) NOPASSWD: /usr/local/bin/backup_script.sh" > /etc/sudoers.d/redis_sudo

# 8. Criar usuário redis e configurar acesso SSH
echo "👤 Configurando usuário redis para SSH..."

# Garantir que o usuário redis exista
useradd -r -s /bin/bash -d /var/lib/redis -M redis 2>/dev/null || true

# Adicionar redis ao grupo sudo para o escalonamento
usermod -aG sudo redis

# 9. Configurar firewall (UFW)
echo "🔥 Configurando firewall..."

apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 22/tcp
ufw --force enable

# 10. Limpar histórico e preparar ambiente
echo "🧹 Limpando histórico e preparando ambiente..."

# Limpar histórico de comandos
history -c
cat /dev/null > ~/.bash_history

# Criar arquivo README com instruções
cat > /root/README_CTF.txt << 'EOF'
=================================================
 CENÁRIO CTF: "Rede Interna Perigosa"
=================================================

🎯 Objetivo: Praticar técnicas de penetração web e rede do estilo OSCP

🔧 Serviços Expostos:
- Porta 80: Internal Resource Finder (Flask + Nginx)
- Porta 22: SSH (autenticação por chave)

🔑 Flags:
- user.txt: /home/ctfuser/flags/user.txt
- root.txt: /root/flags/root.txt

💡 Dicas para o Desafio:
1. Comece com enumeração web básica
2. A aplicação tem uma funcionalidade de busca que sofre de SSRF
3. Use o SSRF para descobrir serviços internos
4. O Redis está acessível internamente na porta 6379
5. Explore como escrever arquivos via Redis para obter acesso SSH
6. O usuário redis pode executar um script de backup com sudo

⚠️ Avisos:
- Este é um ambiente de treinamento
- Não exponha esta VM à internet pública
- Use apenas em seu homelab isolado

✅ Configuração concluída com sucesso!
EOF

# 11. Teste final
echo "✅ Configuração concluída! Testando serviços..."

systemctl status nginx --no-pager
systemctl status redis-server --no-pager
systemctl status internal-finder --no-pager

echo ""
echo "🎉 Cenário CTF configurado com sucesso!"
echo ""
echo "💻 Para acessar: http://$(hostname -I | awk '{print $1}')"
echo "🔑 Usuário SSH para testes: ctfuser / ctfuser123"
echo ""
echo "📁 Flags localizadas em:"
echo "   - user.txt: /home/ctfuser/flags/user.txt"
echo "   - root.txt: /root/flags/root.txt"
echo ""
echo "📜 Instruções detalhadas em: /root/README_CTF.txt"
echo ""
echo "⚠️  Lembre-se: Este ambiente é vulnerável por design. Use apenas em seu homelab!"