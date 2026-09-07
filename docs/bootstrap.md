# Bootstrap — Primeira Execução

O bootstrap cria o **backend remoto do Terraform**: um bucket S3 com versionamento e criptografia, e uma tabela DynamoDB para lock de estado.

> **Execute este passo apenas uma vez**, antes de qualquer `terraform apply` na pasta `terraform/`. A pipeline verifica automaticamente se o bucket já existe e pula o bootstrap se já tiver sido criado.

---

## O que o bootstrap cria

| Recurso | Nome | Finalidade |
|---------|------|-----------|
| S3 Bucket | `bucket-tfstate-1029` | Armazena o arquivo de estado `terraform.tfstate` |
| S3 Versioning | Habilitado | Permite recuperar versões anteriores do estado |
| S3 Encryption | AES256 | Criptografia do estado em repouso |
| DynamoDB Table | `meu-terraform-state-lock` | Previne execuções concorrentes do Terraform |

---

## Passo a passo

### 1. Autentique-se na AWS

```bash
# Verifique se as credenciais estão configuradas
aws sts get-caller-identity
```

### 2. Acesse a pasta de bootstrap

```bash
cd terraform/bootstrap
```

### 3. Inicialize o Terraform

```bash
terraform init
```

### 4. Verifique o que será criado

```bash
terraform plan
```

### 5. Aplique

```bash
terraform apply
```

Confirme digitando `yes` quando solicitado.

**Saída esperada:**
```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:
s3_bucket_name = "bucket-tfstate-1029"
```

---

## Verificar se o bootstrap já foi feito

```bash
aws s3api head-bucket --bucket bucket-tfstate-1029
```

- **Sem erro** → bucket existe, bootstrap já foi executado
- **Erro 404** → bucket não existe, execute o bootstrap

---

## Próximo passo

Com o backend criado, volte à pasta `terraform/` para o provisionamento principal:

```bash
cd ../
```

Veja: [Provisionamento Manual](provisionamento-manual.md)
