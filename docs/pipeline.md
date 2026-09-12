# Pipeline CI/CD

A pipeline é acionada automaticamente em todo push para as branches `main` ou `develop` e executa três jobs encadeados.

---

## Fluxo da pipeline

```
Push → main / develop
         │
         ▼
┌─────────────────────────┐
│  Job 1: Bootstrap       │  Verifica se o bucket S3 já existe.
│  terraform-bootstrap    │  Se não → cria S3 + DynamoDB.
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Job 2: Plan            │  terraform init + terraform plan
│  terraform-plan         │  Salva o tfplan como artefato
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Job 3: Apply           │  terraform apply com o tfplan salvo
│  terraform-apply        │  + conecta ao EKS via kubectl
└─────────────────────────┘  + deploy do New Relic nri-bundle via Helm
```

---

## GitHub Secrets obrigatórios

Acesse: **Repositório → Settings → Secrets and variables → Actions → New repository secret**

| Secret | Descrição | Como obter |
|--------|-----------|-----------|
| `AWS_ACCESS_KEY_ID` | ID da chave de acesso AWS | AWS Academy → **AWS Details** → `aws_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta de acesso AWS | AWS Academy → **AWS Details** → `aws_secret_access_key` |
| `AWS_SESSION_TOKEN` | Token de sessão temporário | AWS Academy → **AWS Details** → `aws_session_token` |
| `NEW_RELIC_ACCOUNT_ID` | ID da conta New Relic | New Relic → canto inferior esquerdo → Account ID |
| `NEW_RELIC_API_KEY` | User API Key do New Relic | New Relic → [API Keys](https://one.newrelic.com/launcher/api-keys-ui.launcher) → tipo **User** |
| `NEW_RELIC_LICENSE_KEY` | Ingest License Key do New Relic | New Relic → [API Keys](https://one.newrelic.com/launcher/api-keys-ui.launcher) → tipo **Ingest - License** |

> ⚠️ **AWS Academy:** Os três secrets AWS (`ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `SESSION_TOKEN`) expiram a cada ~4 horas. **Atualize-os antes de acionar a pipeline a cada nova sessão de laboratório.**

---

## Detalhes de cada job

### Job 1 — Bootstrap

Idempotente. Verifica via `aws s3api head-bucket` se o bucket `bucket-tfstate-1029` já existe.

- Se **não existe**: executa `terraform init` + `terraform apply` na pasta `terraform/bootstrap/`
- Se **já existe**: pula completamente

### Job 2 — Terraform Plan

1. Configura credenciais AWS via `aws-actions/configure-aws-credentials@v4`
2. Instala Terraform 1.15.7
3. Executa `terraform init` com backend S3 configurado via `-backend-config`
4. Executa `terraform plan` passando as variáveis New Relic via `-var`
5. Salva o arquivo `tfplan` como artefato GitHub (retenção: 1 dia)

### Job 3 — Terraform Apply + New Relic

1. Baixa o artefato `tfplan` do Job 2
2. Re-executa `terraform init` com o mesmo backend
3. Aplica com `terraform apply -auto-approve` usando o plan salvo
4. Configura `kubectl` via `aws eks update-kubeconfig`
5. Instala/atualiza o **New Relic nri-bundle** via Helm:
   - `infrastructure.enabled=true` — New Relic Infrastructure Agent
   - `ksm.enabled=true` — Kube State Metrics
   - `kubeEvents.enabled=true` — Eventos Kubernetes
   - `logging.enabled=true` — Coleta de logs dos pods

---

## Atualizar secrets do AWS Academy

Após iniciar uma nova sessão no AWS Academy:

1. Acesse o laboratório → clique em **AWS Details**
2. Copie os três valores (`aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`)
3. No GitHub: **Settings → Secrets and variables → Actions**
4. Atualize os três secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
5. Faça um push ou re-run do último workflow para acionar a pipeline

---

## Re-executar a pipeline manualmente

No GitHub: **Actions → CI/CD Pipeline → Run workflow → Branch: main/develop**

Ou via CLI com `gh`:

```bash
gh workflow run pipeline.yml --ref main
```

---

## Verificar o status da pipeline

```bash
# Listar execuções recentes
gh run list --workflow=pipeline.yml

# Ver detalhes de uma execução específica
gh run view <run-id>

# Acompanhar em tempo real
gh run watch <run-id>
```
