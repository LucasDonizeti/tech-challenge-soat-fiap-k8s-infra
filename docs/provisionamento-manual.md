# Provisionamento Manual

Siga este guia para provisionar toda a infraestrutura localmente sem a pipeline.

> **Pré-requisito:** O [bootstrap](bootstrap.md) já deve ter sido executado antes deste passo.

---

## Passo a passo

### 1. Autentique-se na AWS

```bash
aws sts get-caller-identity
```

Confirme que o `Account` e `Arn` correspondem ao ambiente correto.

### 2. Acesse a pasta do Terraform principal

```bash
cd terraform/
```

### 3. Inicialize com o backend remoto

```bash
terraform init \
  -backend-config="bucket=bucket-tfstate-1029" \
  -backend-config="key=k8s/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=meu-terraform-state-lock" \
  -backend-config="encrypt=true"
```

### 4. Visualize o plano de execução

```bash
terraform plan \
  -var="newrelic_account_id=SEU_ACCOUNT_ID" \
  -var="newrelic_api_key=NRAK-..." \
  -var="newrelic_license_key=..."
```

Revise os recursos que serão criados. Espere ver ~30 recursos novos.

### 5. Aplique a infraestrutura

```bash
terraform apply \
  -var="newrelic_account_id=SEU_ACCOUNT_ID" \
  -var="newrelic_api_key=NRAK-..." \
  -var="newrelic_license_key=..."
```

Confirme com `yes`.

> ⏱️ **Tempo esperado:** 12–18 minutos (EKS cluster + node group + add-ons são os recursos mais lentos).

---

## Verificar o resultado

Ao final, o Terraform exibe os outputs:

```
Outputs:

api_gateway_execution_arn     = "arn:aws:execute-api:us-east-1:..."
api_gateway_id                = "abc123def"
database_subnets              = ["subnet-...", "subnet-..."]
db_subnet_group_name          = "oficina-vpc"
ecr_auth_lambda_url           = "123456789.dkr.ecr.us-east-1.amazonaws.com/auth-lambda"
ecr_repository_url            = "123456789.dkr.ecr.us-east-1.amazonaws.com/oficina-api"
eks_cluster_endpoint          = "https://XXXX.gr7.us-east-1.eks.amazonaws.com"
eks_cluster_name              = "oficina-cluster"
eks_node_security_group_id    = "sg-..."
newrelic_integration_role_arn = "arn:aws:iam::...:role/LabRole"
private_subnets               = ["subnet-...", "subnet-..."]
vpc_id                        = "vpc-..."
```

Para ver os outputs a qualquer momento:

```bash
terraform output
```

Para ver um output específico:

```bash
terraform output api_gateway_id
terraform output ecr_repository_url
```

---

## Conectar ao cluster EKS

Após o apply, configure o `kubectl`:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name oficina-cluster
```

Verifique a conexão:

```bash
kubectl get nodes
kubectl get pods -A
```

---

## Obter o URL do API Gateway

```bash
# Via Terraform output
terraform output -raw api_gateway_endpoint

# Via AWS CLI
aws apigatewayv2 get-apis \
  --region us-east-1 \
  --query 'Items[?Name==`oficina-api-gateway`].ApiEndpoint' \
  --output text
```

O URL terá o formato:
```
https://<api-id>.execute-api.us-east-1.amazonaws.com
```

> Após o deploy da aplicação, o Swagger estará disponível em:
> `https://<api-id>.execute-api.us-east-1.amazonaws.com/swagger-ui/index.html`

---

## Destruir a infraestrutura

Para economizar créditos do AWS Academy, destrua o ambiente quando não estiver em uso:

```bash
terraform destroy \
  -var="newrelic_account_id=SEU_ACCOUNT_ID" \
  -var="newrelic_api_key=NRAK-..." \
  -var="newrelic_license_key=..."
```

> ⚠️ Destruir o EKS cluster **não destroi** o bucket S3 de estado (`bucket-tfstate-1029`), pois ele tem `force_destroy = false`. O estado do Terraform é preservado para o próximo `apply`.

---

## Reprovisionar após nova sessão do Academy

As credenciais do Academy expiram a cada ~4 horas. Para reprovisionar:

```bash
# 1. Atualize as credenciais AWS
aws configure set aws_access_key_id     "NOVA_KEY"
aws configure set aws_secret_access_key "NOVO_SECRET"
aws configure set aws_session_token     "NOVO_TOKEN"

# 2. Re-aplique (Terraform detecta automaticamente o que precisa recriar)
cd terraform/
terraform apply \
  -var="newrelic_account_id=..." \
  -var="newrelic_api_key=..." \
  -var="newrelic_license_key=..."
```
