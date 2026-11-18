#!/usr/bin/env bash
# ==============================================================================
# Script de Setup, Reset e Git Hook operando direto na pasta ./vuln local
# ==============================================================================

set -e

# Pega o caminho absoluto da pasta vuln ao lado do script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$BASE_DIR/vuln"
GITLEAKS_IMAGE="docker.io/zricethezav/gitleaks:latest"

install_hook_file() {
  cat <<EOF >"$LAB_DIR/.git/hooks/pre-commit"
#!/usr/bin/env bash
echo ""
echo "🛡️  [DevSecOps Hook] Iniciando varredura preventiva do Gitleaks antes do commit..."
podman run --rm -v "\$(pwd):/path:Z" $GITLEAKS_IMAGE protect --source="/path" --staged -v

if [ \$? -ne 0 ]; then
    echo ""
    echo "❌ [BLOQUEADO] O Git abortou o seu commit automaticamente!"
    echo "⚠️  Motivo: Credenciais ou chaves de API foram detectadas no código."
    echo "💡 Solução: Mova os segredos para o arquivo .env antes de comitar."
    echo ""
    exit 1
fi
echo "✅ [DevSecOps Hook] Nenhum segredo exposto. Commit autorizado!"
EOF
}

setup_or_reset_lab() {
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # Remove apenas o histórico Git anterior da pasta vuln para zerar a demo
  rm -rf "$LAB_DIR/.git"

  # Inicializa o Git isolado na pasta vuln
  git init -q -b main
  git config --local user.name "Dev Apressado"
  git config --local user.email "dev@exemplo.local"
  git config --local commit.gpgsign false

  # 1. Atualiza o app.py SEM a palavra 'EXAMPLE' (para o Gitleaks não ignorar!)
  cat <<'EOF' >"$LAB_DIR/app.py"
import urllib.request
import json

# ==========================================================
# Script gerado via IA para conectar no banco e na API
# ==========================================================

# ERRO FATAL: Credenciais chumbadas (Hardcoded) direto no código!
AWS_ACCESS_KEY_ID = "AKIAX7V5JQ9M2N8KL4P1"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzX9vK2mL8q"
GITHUB_TOKEN = "ghp_9aBcDeFgHiJkLmNoPqRsTuVwXyZ012345678"
DB_URI = "postgresql://admin:SenhaSuperSecreta123!@db.meuservidor.com:5432/producao"

def conectar_servicos():
    print(f"[*] Conectando ao banco de produção...")
    print(f"[*] Autenticando na nuvem com a chave: {AWS_ACCESS_KEY_ID[:8]}...")
    print("[+] Tudo funcionando perfeitamente na minha máquina!")

if __name__ == "__main__":
    conectar_servicos()
EOF

  # 2. Garante o app_seguro.py
  cat <<'EOF' >"$LAB_DIR/app_seguro.py"
import os

# CORRETO: Buscando segredos das variáveis de ambiente do Sistema Operacional
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
DB_URI = os.getenv("DB_URI")

def conectar_servicos():
    if not AWS_ACCESS_KEY_ID or not DB_URI:
        raise ValueError("[ERRO] Variáveis de ambiente não configuradas no arquivo .env!")
    
    print("[+] Conectado com segurança sem expor senhas no código-fonte!")

if __name__ == "__main__":
    conectar_servicos()
EOF

  # 3. Cria .env e .gitignore
  cat <<'EOF' >"$LAB_DIR/.env"
AWS_ACCESS_KEY_ID="AKIAX7V5JQ9M2N8KL4P1"
AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYzX9vK2mL8q"
GITHUB_TOKEN="ghp_9aBcDeFgHiJkLmNoPqRsTuVwXyZ012345678"
DB_URI="postgresql://admin:SenhaSuperSecreta123!@db.meuservidor.com:5432/producao"
EOF

  cat <<'EOF' >"$LAB_DIR/.gitignore"
.env
*.key
*.pem
__pycache__/
EOF

  # Commit inicial limpo com o .gitignore
  git add .gitignore
  git commit -q -m "chore: commit inicial com gitignore"

  # Instala e JÁ ATIVA o hook pre-commit por padrão!
  install_hook_file
  chmod +x "$LAB_DIR/.git/hooks/pre-commit"

  echo ""
  echo "[+] Tudo pronto dentro da sua pasta: $LAB_DIR"
  echo "[+] O Hook pre-commit JÁ ESTÁ ATIVO!"
  echo "----------------------------------------------------------------"
  echo "Agora basta rodar:"
  echo "  cd vuln"
  echo "  git add app.py"
  echo "  git commit -m 'feat: integracao com ia pronta'"
  echo "----------------------------------------------------------------"
}

case "${1:-setup}" in
setup)
  echo "[*] Garantindo imagem do Gitleaks no cache do Podman..."
  podman pull -q "$GITLEAKS_IMAGE" >/dev/null
  setup_or_reset_lab
  ;;
reset)
  echo "[*] Resetando o histórico Git da pasta ./vuln..."
  setup_or_reset_lab
  ;;
hook-off)
  chmod -x "$LAB_DIR/.git/hooks/pre-commit" 2>/dev/null || true
  echo "[-] Hook desativado em ./vuln (o commit sujo vai passar)."
  ;;
hook-on)
  install_hook_file
  chmod +x "$LAB_DIR/.git/hooks/pre-commit"
  echo "[+] Hook ativado em ./vuln (o commit sujo será bloqueado)."
  ;;
clean)
  echo "[*] Limpando repositório Git oculto de ./vuln e removendo imagem..."
  rm -rf "$LAB_DIR/.git" "$LAB_DIR/.env" "$LAB_DIR/.gitignore"
  podman rmi -f "$GITLEAKS_IMAGE" 2>/dev/null || true
  echo "[+] Limpeza concluída! Seus arquivos app.py e app_seguro.py continuam lá."
  ;;
*)
  echo "Uso: $0 [setup|reset|hook-on|hook-off|clean]"
  ;;
esac
