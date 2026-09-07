# Recursos Provisionados

Inventário completo de todos os recursos AWS e New Relic criados por este repositório.

---

## Diagrama de Rede

```
VPC: oficina-vpc (10.0.0.0/16)
│
├── us-east-1a                          us-east-1b
│   ├── Public Subnet (10.0.101.0/24)   ├── Public Subnet (10.0.102.0/24)
│   ├── Private Subnet (10.0.1.0/24)    ├── Private Subnet (10.0.2.0/24)
│   └── DB Subnet (10.0.201.0/24)       └── DB Subnet (10.0.202.0/24)
│
├── NAT Gateway (single, na public subnet us-east-1a)
│   └── Permite que private subnets acessem a internet (ECR pull, New Relic, etc.)
│
└── Internet Gateway (gerenciado pelo módulo VPC)
```

---

## Módulo VPC

| Recurso | Nome / Valor | Observações |
|---------|-------------|-------------|
| VPC | `oficina-vpc` | CIDR `10.0.0.0/16` |
| Public Subnets | `10.0.101.0/24`, `10.0.102.0/24` | AZs a e b |
| Private Subnets | `10.0.1.0/24`, `10.0.2.0/24` | AZs a e b — EKS nodes e Lambda |
| Database Subnets | `10.0.201.0/24`, `10.0.202.0/24` | AZs a e b — RDS (criado no db-infra) |
| NAT Gateway | 1 instância | `single_nat_gateway=true` para reduzir custo |
| DB Subnet Group | `oficina-vpc` | Criado automaticamente pelo módulo |
| DNS Hostnames | Habilitado | Necessário para EKS e RDS |
| DNS Support | Habilitado | Necessário para resolução interna |

**Tags nas subnets para Kubernetes:**
- Public subnets: `kubernetes.io/role/elb = 1`
- Private subnets: `kubernetes.io/role/internal-elb = 1`

---

## Módulo EKS

| Recurso | Configuração | Observações |
|---------|-------------|-------------|
| EKS Cluster | `oficina-cluster` v1.36 | `role_arn = LabRole` |
| Endpoint | Público + Privado | `endpoint_public_access = true` |
| Auth Mode | API | `authentication_mode = API` |
| Node Group | `main` — `t3.medium` | 1 nó desejado, máximo 2 |
| Node Subnets | Private Subnets | Nodes não expostos diretamente |
| Node IAM Role | `LabRole` | Restrição do AWS Academy |
| Security Group Nodes | `oficina-cluster-nodes-sg` | Regras: inter-node, control-plane, NodePort 30000–32767, Kubelet 10250, HTTPS 443 |
| Add-on vpc-cni | OVERWRITE | Gerenciamento de IPs dos pods |
| Add-on kube-proxy | OVERWRITE | Roteamento de serviços |
| Add-on coredns | OVERWRITE | Resolução DNS interna |
| Access Entry | `LabRole` | `AmazonEKSClusterAdminPolicy` |

**Portas abertas no Security Group dos nodes:**

| Porta | Protocolo | Origem | Finalidade |
|-------|-----------|--------|-----------|
| All | All | Self (nodes) | Comunicação inter-nodes |
| 1025–65535 | TCP | `0.0.0.0/0` | Control plane → nodes |
| 30000–32767 | TCP | `0.0.0.0/0` | NodePort range (Load Balancer) |
| 30080 | TCP | `0.0.0.0/0` | Health check NLB |
| 10250 | TCP | `0.0.0.0/0` | Kubelet (control plane) |
| 443 | TCP | `0.0.0.0/0` | HTTPS control plane |

---

## Módulo ECR

Dois repositórios criados com a mesma configuração:

| Repositório | URL | Finalidade |
|-------------|-----|-----------|
| `oficina-api` | `<account>.dkr.ecr.us-east-1.amazonaws.com/oficina-api` | Imagens da API principal (Spring Boot) |
| `auth-lambda` | `<account>.dkr.ecr.us-east-1.amazonaws.com/auth-lambda` | Imagens do Lambda Authorizer |

**Configurações comuns:**
- Tag mutability: `MUTABLE`
- Scan on push: `true` (verifica vulnerabilidades ao fazer push)
- Lifecycle policy: mantém as **5 últimas imagens** (expira as mais antigas)
- Acesso: somente `LabRole` tem permissão de leitura/escrita

---

## Módulo API Gateway

Fluxo de roteamento completo:

```
Internet → API GW HTTP v2 → VPC Link → NLB Interno → Target Group → EKS NodePort 30080
```

| Recurso | Nome / Configuração | Observações |
|---------|--------------------|----|
| API Gateway | `oficina-api-gateway` | HTTP API v2 |
| Stage | `$default` | `auto_deploy = true` |
| Rota catch-all | `ANY /{proxy+}` | Repassa tudo para o EKS |
| Integração | `HTTP_PROXY` via `VPC_LINK` | Sem transformação de payload |
| VPC Link | `oficina-api-gateway-vpc-link` | Conecta API GW à rede privada |
| VPC Link SG | `oficina-api-gateway-vpc-link-sg` | Permite todo tráfego do CIDR da VPC |
| NLB Interno | `oficina-api-gateway-nlb` | Layer 4, subnets privadas |
| NLB Listener | Port 80, protocolo TCP | Encaminha para o Target Group |
| Target Group | `ofic-*`, port 30080 | Tipo `instance`, HTTP health check em `/actuator/health` |
| ASG Attachment | automático | Registra novos nodes EKS no Target Group ao escalar |

**Health check do Target Group:**
- Protocolo: HTTP
- Porta: 30080
- Path: `/actuator/health`
- Matcher: `200`
- Interval: 10s
- Thresholds: 2 healthy / 2 unhealthy

---

## Módulo New Relic

| Recurso | Configuração | Observações |
|---------|-------------|-------------|
| Synthetic Monitor | `Ping oficina-api` | Tipo SIMPLE, a cada 2 minutos |
| Monitor URL | `{api_endpoint}/actuator/health/liveness` | Verifica a cadeia completa |
| Monitor Região | `AWS_SA_EAST_1` | São Paulo (mais próximo) |
| Dashboard | `Oficina API Dashboard` | 4 páginas: Cluster Overview, Logs, Ordens de Serviço, Healthcheck |

**Páginas do Dashboard:**
1. **Cluster Overview** — CPU, memória, storage, network, replicas, pods
2. **Logs** — Volume de logs por tempo, tabela de logs recentes
3. **Ordens de Serviço** — Volume de OS criadas, tempo médio por status, latência, falhas
4. **Healthcheck** — Tempo de resposta do Synthetic Monitor, uptime %, error codes

---

## Backend de State Terraform

Criado pelo bootstrap — permanece após `terraform destroy`:

| Recurso | Nome | Configuração |
|---------|------|-------------|
| S3 Bucket | `bucket-tfstate-1029` | Versioning habilitado, AES256, `force_destroy=false` |
| DynamoDB Table | `meu-terraform-state-lock` | PAY_PER_REQUEST, hash_key `LockID` |
| State Key | `k8s/terraform.tfstate` | Caminho do estado dentro do bucket |

---

## Custo estimado (AWS Academy)

| Recurso | Custo aproximado/h | Observação |
|---------|-------------------|-----------|
| EKS Control Plane | $0.10/h | Cobrado mesmo sem nodes |
| EC2 t3.medium (1 nó) | ~$0.047/h | ~$1.13/dia |
| NAT Gateway | $0.045/h + tráfego | ~$1.08/dia |
| NLB | $0.008/h | Mínimo |
| API Gateway | Pay per use | Mínimo no volume acadêmico |
| RDS (db-infra) | ~$0.017/h | Provisionado separadamente |
| **Total estimado** | **~$0.22/h** | **~$5.3/dia** |

> 💡 **Dica:** Destrua a infraestrutura com `terraform destroy` quando não estiver usando. O bucket S3 de state é preservado automaticamente.
