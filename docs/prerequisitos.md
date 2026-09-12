# Pré-requisitos e Configuração

## Ferramentas necessárias

| Ferramenta | Versão mínima | Instalação |
|-----------|--------------|-----------|
| Terraform | >= 1.6.0 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | v2 | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| kubectl | >= 1.28 | https://kubernetes.io/docs/tasks/tools/ |
| Helm | >= 3.14 | https://helm.sh/docs/intro/install/ |

---

## 1. Configurar AWS CLI

### Ambiente normal (credenciais permanentes)

```bash
aws configure
```

Preencha:
```
AWS Access Key ID:     <seu-access-key>
AWS Secret Access Key: <seu-secret-key>
Default region name:   us-east-1
Default output format: json
```

### AWS Academy (sessão temporária)

O AWS Academy usa sessões temporárias com `SessionToken`. Configure as três variáveis de uma vez:

```bash
aws configure set aws_access_key_id     "ASIA..."
aws configure set aws_secret_access_key "..."
aws configure set aws_session_token     "..."
aws configure set region                "us-east-1"
```

Ou exporte como variáveis de ambiente (mais prático para sessões curtas):

```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

> ⚠️ **Atenção AWS Academy:** As credenciais expiram a cada ~4 horas. Você precisa atualizar os três valores sempre que iniciar uma nova sessão no laboratório.

### Verificar autenticação

```bash
aws sts get-caller-identity
```

Saída esperada:
```json
{
    "UserId": "AROA...",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/LabRole/..."
}
```

---

## 2. Variáveis do Terraform

O Terraform precisa de três variáveis relacionadas ao New Relic. **Nunca as coloque no código-fonte.**

Crie um arquivo `terraform/terraform.tfvars` (está no `.gitignore`):

```hcl
# terraform/terraform.tfvars

newrelic_account_id  = "SEU_ACCOUNT_ID"
newrelic_api_key     = "NRAK-..."
newrelic_license_key = "..."
```

Ou passe via linha de comando:

```bash
terraform apply \
  -var="newrelic_account_id=SEU_ACCOUNT_ID" \
  -var="newrelic_api_key=NRAK-..." \
  -var="newrelic_license_key=..."
```

### Como obter as credenciais do New Relic

| Variável | Onde encontrar |
|----------|---------------|
| `newrelic_account_id` | New Relic → clique no nome da conta (canto inferior esquerdo) → Account ID |
| `newrelic_api_key` | New Relic → **[API Keys](https://one.newrelic.com/launcher/api-keys-ui.launcher)** → Create key → tipo **User** |
| `newrelic_license_key` | New Relic → **[API Keys](https://one.newrelic.com/launcher/api-keys-ui.launcher)** → Create key → tipo **Ingest - License** |

---

## 3. Variáveis opcionais (com padrões)

Estas variáveis têm valores padrão e geralmente não precisam ser alteradas:

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `region` | `us-east-1` | Região AWS |
| `app_name` | `oficina` | Prefixo dos recursos criados |
| `vpc_cidr` | `10.0.0.0/16` | CIDR da VPC |
