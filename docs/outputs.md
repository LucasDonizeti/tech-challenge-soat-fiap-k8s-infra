# Outputs e Integração com Outros Repositórios

Este repositório exporta outputs via Terraform que são consumidos pelos repositórios `db-infra` e `auth-lambda` usando `terraform_remote_state`.

---

## Todos os outputs

```bash
# Ver todos os outputs após o apply
terraform output
```

| Output | Tipo | Descrição | Consumido por |
|--------|------|-----------|--------------|
| `vpc_id` | string | ID da VPC | db-infra, auth-lambda |
| `private_subnets` | list(string) | IDs das subnets privadas (EKS nodes + Lambda) | auth-lambda |
| `database_subnets` | list(string) | IDs das subnets de banco de dados | db-infra |
| `db_subnet_group_name` | string | Nome do subnet group do RDS | db-infra |
| `eks_cluster_name` | string | Nome do cluster EKS (`oficina-cluster`) | pipeline principal |
| `eks_cluster_endpoint` | string | Endpoint HTTPS do cluster EKS | pipeline principal |
| `eks_node_security_group_id` | string | SG dos nodes EKS (usado pelo RDS para liberar porta 3306) | db-infra, auth-lambda |
| `ecr_repository_url` | string | URL do ECR `oficina-api` | pipeline principal |
| `ecr_auth_lambda_url` | string | URL do ECR `auth-lambda` | auth-lambda |
| `api_gateway_id` | string | ID do API Gateway | auth-lambda |
| `api_gateway_execution_arn` | string | ARN de execução do API Gateway (permissões Lambda) | auth-lambda |
| `newrelic_integration_role_arn` | string | ARN da LabRole para integração New Relic | informativo |

---

## Como os outros repositórios leem esses outputs

Os demais repositórios usam o bloco `terraform_remote_state` apontando para o mesmo bucket S3:

```hcl
# Exemplo do db-infra/terraform/main.tf
data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket = "bucket-tfstate-1029"
    key    = "k8s/terraform.tfstate"
    region = "us-east-1"
  }
}

# Usando os outputs
module "rds" {
  source               = "./modules/rds"
  subnet_ids           = data.terraform_remote_state.k8s.outputs.database_subnets
  db_subnet_group_name = data.terraform_remote_state.k8s.outputs.db_subnet_group_name
  vpc_id               = data.terraform_remote_state.k8s.outputs.vpc_id
  eks_node_sg_id       = data.terraform_remote_state.k8s.outputs.eks_node_security_group_id
}
```

---

## Como ler outputs manualmente

```bash
# Ir para a pasta terraform
cd terraform/

# Todos os outputs
terraform output

# Um output específico (sem aspas)
terraform output -raw vpc_id
terraform output -raw eks_cluster_name
terraform output -raw ecr_repository_url
terraform output -raw api_gateway_endpoint

# URL do API Gateway formatada
echo "API Gateway URL: $(terraform output -raw api_gateway_endpoint)"

# Swagger após deploy da aplicação
echo "Swagger: $(terraform output -raw api_gateway_endpoint)/swagger-ui/index.html"

# URL do ECR para a aplicação principal
echo "ECR URL: $(terraform output -raw ecr_repository_url)"
```

---

## Mapa de dependências completo

```
k8s-infra (este repo)
│
│  Outputs consumidos:
├─────────────────────────────────────────────────┐
│                                                  │
▼                                                  ▼
db-infra                                    auth-lambda
├── vpc_id                                  ├── vpc_id
├── database_subnets                        ├── private_subnets
├── db_subnet_group_name                    ├── eks_node_security_group_id
└── eks_node_security_group_id              ├── ecr_auth_lambda_url
                                            ├── api_gateway_id
                                            └── api_gateway_execution_arn

Pipeline do repo principal (GitHub Actions):
├── eks_cluster_name  → aws eks update-kubeconfig
├── ecr_repository_url → docker push
└── api_gateway_endpoint → testes de smoke
```

---

## Verificar se os outputs estão disponíveis

Antes de rodar os outros repositórios, confirme que os outputs existem:

```bash
# Verificar que o state tem outputs
aws s3 cp s3://bucket-tfstate-1029/k8s/terraform.tfstate - \
  | python3 -c "
import sys, json
state = json.load(sys.stdin)
outputs = state.get('outputs', {})
for k, v in outputs.items():
    print(f'{k}: {v[\"value\"] if not v.get(\"sensitive\") else \"<sensitive>\"}')"
```
