# 🔧 Ferramentas de Pentest - OWASP & PTES

Repositório de ferramentas, scripts e anotações para testes de penetração baseados nas metodologias OWASP e PTES.

## 📋 Índice
- [Metodologias](#-metodologias)
- [Estrutura do Diretório](#-estrutura-do-diretório)
- [Ferramentas por Fase](#-ferramentas-por-fase)
- [Scripts de Automação](#-scripts-de-automação)
- [Anotações e Dicas](#-anotações-e-dicas)
- [Cheatsheets](#-cheatsheets)
- [Contribuição](#-contribuição)

## 🎯 Metodologias

### **OWASP Testing Guide**
- Reconhecimento
- Análise de Vulnerabilidades
- Exploração
- Pós-Exploração
- Relatórios

### **PTES (Penetration Testing Execution Standard)**
1. Pré-Engajamento
2. Coleta de Inteligência
3. Modelagem de Ameaças
4. Análise de Vulnerabilidades
5. Exploração
6. Pós-Exploração
7. Relatório

## 📁 Estrutura do Diretório

```
Ferramentas/
├── 📂 01-Reconhecimento/
├── 📂 02-Varredura/
├── 📂 03-Exploracao/
├── 📂 04-Pos-Exploracao/
├── 📂 05-Relatorios/
├── 📂 scripts/
├── 📂 cheatsheets/
├── 📂 anotacoes/
└── 📂 templates/
```

## 🔧 Ferramentas por Fase

### 1. 🕵️ Reconhecimento (OSINT)
- **Whois**: `whois dominio.com`
- **Dig**: `dig dominio.com ANY`
- **theHarvester**: `python3 theHarvester.py -d dominio.com -l 500 -b google`
- **Sublist3r**: `python3 sublist3r.py -d dominio.com`
- **Amass**: `amass enum -d dominio.com`

### 2. 🔍 Varredura e Enumeração
- **Nmap**: 
  ```bash
  nmap -sC -sV -O -p- -T4 alvo.com
  nmap --script vuln alvo.com
  ```
- **Nikto**: `nikto -h http://alvo.com`
- **Gobuster**: 
  ```bash
  gobuster dir -u http://alvo.com -w /usr/share/wordlists/dirb/common.txt
  gobuster dns -d alvo.com -w subdomains.txt
  ```
- **Dirb**: `dirb http://alvo.com /usr/share/wordlists/dirb/common.txt`

### 3. ⚡ Exploração
- **Metasploit**: 
  ```bash
  msfconsole
  use exploit/...
  set RHOSTS alvo.com
  exploit
  ```
- **SQLmap**: 
  ```bash
  sqlmap -u "http://alvo.com/page.php?id=1" --dbs
  sqlmap -u "http://alvo.com/page.php?id=1" -D database --tables
  ```
- **Burp Suite**: Intercept, Repeater, Intruder
- **John the Ripper**: `john --wordlist=rockyou.txt hashfile`

### 4. 🎯 Pós-Exploração
- **Mimikatz**: Extração de credenciais Windows
- **LinPEAS**: Enumeração Linux privilege escalation
- **WinPEAS**: Enumeração Windows privilege escalation
- **BloodHound**: Análise de relações no Active Directory

### 5. 📊 Relatórios
- **Dradis**: Framework colaborativo
- **Serpico**: Geração de relatórios
- **LaTeX Templates**: Relatórios profissionais



## 🚀 Cheatsheets

### Comandos Essenciais
| Ferramenta | Comando | Descrição |
|------------|---------|-----------|
| **curl** | `curl -i http://alvo.com` | Headers detalhados |
| **netcat** | `nc -nv 192.168.1.1 80` | Conexão TCP |
| **tcpdump** | `tcpdump -i eth0 host alvo.com` | Captura de tráfego |

### Wordlists Recomendadas
- `rockyou.txt` - Senhas comuns
- `SecLists` - Coleção completa
- `dirb/*.txt` - Diretórios comuns
- `subdomains-top1million.txt` - Subdomínios

## 🤝 Contribuição

1. Fork o repositório
2. Crie sua branch: `git checkout -b feature/nova-ferramenta`
3. Commit suas mudanças: `git commit -am 'Adiciona nova ferramenta'`
4. Push para a branch: `git push origin feature/nova-ferramenta`
5. Abra um Pull Request

## ⚠️ Disclaimer

Este repositório é apenas para fins educacionais e de pesquisa. Use apenas em sistemas que você possui permissão explícita para testar. O uso indevido dessas ferramentas é de sua inteira responsabilidade.

## 📚 Recursos Úteis

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PTES Technical Guidelines](http://www.pentest-standard.org/)
- [Kali Tools Documentation](https://www.kali.org/tools/)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)

---

**📅 Última atualização: Janeiro 2026**  
**🔒 Use com responsabilidade e sempre com autorização**
