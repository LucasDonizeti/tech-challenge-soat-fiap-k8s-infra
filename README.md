# 🏗️ tech-challenge-soat-fiap-k8s-infra

Infraestrutura base da plataforma **Sistema de Gestão de Oficina** provisionada via **Terraform** na AWS.

Este repositório é o **primeiro a ser executado** na cadeia de provisionamento. Ele cria todos os recursos compartilhados que os demais repositórios dependem via `terraform_remote_state`.

---

## 📑 Documentação

| Documento | Descrição |
|-----------|-----------|
| [Recursos Provisionados](docs/recursos-provisionados.md) | Inventário completo de todos os recursos AWS criados |
| [Pré-requisitos e Configuração](docs/prerequisitos.md) | AWS CLI, Terraform, kubectl, Helm e variáveis necessárias |
| [Bootstrap (Primeira Execução)](docs/bootstrap.md) | Como criar o backend remoto do Terraform (S3 + DynamoDB) |
| [Provisionamento Manual](docs/provisionamento-manual.md) | Passo a passo para aplicar o Terraform localmente |
| [Pipeline CI/CD](docs/pipeline.md) | Como funciona a pipeline automática e os GitHub Secrets necessários |
| [Comandos Úteis](docs/comandos-uteis.md) | AWS CLI, kubectl, Helm e Terraform — referência rápida |
| [Outputs e Integração](docs/outputs.md) | Todos os outputs exportados para os outros repositórios |
| [Observabilidade — New Relic](docs/observabilidade.md) | Dashboard, Synthetic Monitor e integração Kubernetes |

---

## ⚡ Visão Rápida

```
┌─────────────────────────────────────────────────────────────┐
│  1. Bootstrap  →  Cria S3 + DynamoDB (state remoto)         │
│  2. terraform apply  →  Provisiona toda a infraestrutura    │
│  3. Outros repos leem os outputs via terraform_remote_state │
└─────────────────────────────────────────────────────────────┘
```

**Recursos criados:**

| Recurso | Tipo | Finalidade |
|---------|------|-----------|
| VPC | `10.0.0.0/16` em 2 AZs | Rede isolada para todos os serviços |
| EKS Cluster | v1.36 | Orquestração dos pods da aplicação |
| Node Group | `t3.medium` (1–2 nós) | Workers do cluster em private subnets |
| ECR `oficina-api` | Privado | Imagens Docker da API principal |
| ECR `auth-lambda` | Privado | Imagens Docker do Lambda Authorizer |
| API Gateway HTTP v2 | `$default` stage | Ponto de entrada único da plataforma |
| NLB Interno | Port 80 → 30080 | Roteamento API GW → EKS NodePort |
| VPC Link | Private subnets | Conexão privada API GW → NLB |
| S3 + DynamoDB | `bucket-tfstate-1029` | State remoto do Terraform |
| New Relic Monitor | Ping a cada 2 min | Health check externo |
| New Relic Dashboard | 4 páginas | Observabilidade da plataforma |

---

## 🔗 Arquitetura

```
Internet
    │
    ▼
API Gateway HTTP v2
    │  VPC Link (private)
    ▼
NLB Interno ─── Target Group (NodePort 30080)
    │                    │
    │          ┌─────────▼──────────┐
    │          │   EKS Cluster      │
    │          │   oficina-cluster  │
    │          │   (t3.medium)      │
    │          └────────────────────┘
    │
    ├── VPC 10.0.0.0/16
    │   ├── Public Subnets   (10.0.101.0/24, 10.0.102.0/24)
    │   ├── Private Subnets  (10.0.1.0/24, 10.0.2.0/24)
    │   └── Database Subnets (10.0.201.0/24, 10.0.202.0/24)
    │
    ├── ECR: oficina-api
    ├── ECR: auth-lambda
    │
    └── S3 + DynamoDB (Terraform State)
```

---

## 🗂️ Estrutura do Repositório

```
.
├── .github/
│   └── workflows/
│       └── pipeline.yml          # Pipeline CI/CD (Bootstrap → Plan → Apply)
├── terraform/
│   ├── bootstrap/
│   │   └── main.tf               # Cria S3 + DynamoDB (executar UMA VEZ)
│   ├── modules/
│   │   ├── vpc/                  # VPC, subnets, NAT Gateway
│   │   ├── eks/                  # Cluster EKS + Node Group + Add-ons
│   │   ├── ecr/                  # Repositórios ECR (reutilizável)
│   │   ├── api_gateway/          # API GW + VPC Link + NLB + Target Group
│   │   └── new_relic/            # Synthetic Monitor + Dashboard
│   ├── main.tf                   # Orquestração de todos os módulos
│   ├── variables.tf              # Variáveis de entrada
│   ├── outputs.tf                # Outputs exportados para outros repos
│   ├── backend.tf                # Configuração do state remoto S3
│   └── provider.tf               # Providers AWS + New Relic
└── docs/                         # Documentação detalhada
```

---

## 🔄 Ordem de Provisionamento

Este repositório é o **passo 1** na cadeia:

```
[1] k8s-infra (este repo)   →  VPC, EKS, ECR, API GW, New Relic
[2] db-infra                →  RDS MySQL (lê outputs do k8s-infra)
[3] auth-lambda             →  Lambda + rota API GW (lê outputs do k8s-infra)
[4] Deploy da aplicação     →  Helm → EKS (pipeline do repo principal)
```

---

## 🔗 Links Relacionados

- [Repositório principal — oficina-api](../tech-challenge-soat-fiap)
- [Repositório — db-infra](../tech-challenge-soat-fiap-db-infra)
- [Repositório — auth-lambda](../tech-challenge-soat-fiap-auth-lambda)
- [Swagger UI da API](https://&lt;API_GATEWAY_URL&gt;/swagger-ui/index.html) *(disponível após deploy da aplicação)*
- [New Relic Dashboard](https://one.newrelic.com)

---

## 🛠️ Tecnologias

| Tecnologia | Versão | Uso |
|-----------|--------|-----|
| Terraform | >= 1.6.0 | Provisionamento de infraestrutura |
| AWS Provider | ~> 6.0 (6.52.0) | Recursos AWS |
| New Relic Provider | ~> 3.0 (3.96.4) | Observabilidade |
| AWS EKS | 1.36 | Orquestração Kubernetes |
| terraform-aws-modules/vpc | 6.6.1 | VPC com boas práticas |
| terraform-aws-modules/ecr | 2.3.0 | Container Registry |
