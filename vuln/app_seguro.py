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
