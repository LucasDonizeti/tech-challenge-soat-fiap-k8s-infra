# Comandos Úteis

Referência rápida de comandos AWS CLI, kubectl, Helm e Terraform para operar a infraestrutura do `k8s-infra`.

---

## AWS CLI

### Autenticação e identidade

```bash
# Verificar identidade e conta ativa
aws sts get-caller-identity

# Configurar credenciais normais
aws configure

# Configurar credenciais do AWS Academy (token de sessão)
aws configure set aws_access_key_id     "ASIA..."
aws configure set aws_secret_access_key "..."
aws configure set aws_session_token     "..."
aws configure set region                "us-east-1"

# Exportar como variáveis de ambiente (alternativa mais rápida)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### EKS

```bash
# Configurar kubectl para o cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name oficina-cluster

# Listar clusters existentes
aws eks list-clusters --region us-east-1

# Descrever o cluster
aws eks describe-cluster \
  --name oficina-cluster \
  --region us-east-1

# Ver node groups
aws eks list-nodegroups \
  --cluster-name oficina-cluster \
  --region us-east-1

# Descrever node group
aws eks describe-nodegroup \
  --cluster-name oficina-cluster \
  --nodegroup-name main \
  --region us-east-1
```

### API Gateway

```bash
# Listar APIs existentes
aws apigatewayv2 get-apis --region us-east-1

# Obter URL do API Gateway pelo nome
aws apigatewayv2 get-apis \
  --region us-east-1 \
  --query 'Items[?Name==`oficina-api-gateway`].ApiEndpoint' \
  --output text

# Listar rotas da API
aws apigatewayv2 get-routes \
  --api-id <API_ID> \
  --region us-east-1

# Obter ID da API (necessário para outros comandos)
API_ID=$(aws apigatewayv2 get-apis \
  --region us-east-1 \
  --query 'Items[?Name==`oficina-api-gateway`].ApiId' \
  --output text)
echo "API ID: $API_ID"
```

### ECR

```bash
# Listar repositórios
aws ecr describe-repositories --region us-east-1

# Login no ECR (necessário antes de push/pull manual)
aws ecr get-login-password --region us-east-1 \
  | docker login \
    --username AWS \
    --password-stdin \
    <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Listar imagens do repositório oficina-api
aws ecr list-images \
  --repository-name oficina-api \
  --region us-east-1

# Obter a URL do repositório
aws ecr describe-repositories \
  --repository-names oficina-api \
  --region us-east-1 \
  --query 'repositories[0].repositoryUri' \
  --output text
```

### VPC e Subnets

```bash
# Listar VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=oficina" \
  --region us-east-1

# Listar subnets da VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --region us-east-1 \
  --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}'
```

### S3 e Terraform State

```bash
# Verificar se o bucket de state existe
aws s3api head-bucket --bucket bucket-tfstate-1029

# Listar arquivos no bucket
aws s3 ls s3://bucket-tfstate-1029/ --recursive

# Baixar o state atual (para inspecionar)
aws s3 cp s3://bucket-tfstate-1029/k8s/terraform.tfstate ./tfstate-backup.json
```

---

## kubectl

### Contexto e conexão

```bash
# Ver contexto atual
kubectl config current-context

# Listar contextos disponíveis
kubectl config get-contexts

# Trocar de contexto (se houver múltiplos clusters)
kubectl config use-context <nome-do-contexto>

# Ver configuração completa
kubectl config view
```

### Nodes e Cluster

```bash
# Listar nodes
kubectl get nodes

# Listar nodes com detalhes (IPs, roles, versão)
kubectl get nodes -o wide

# Descrever um node específico
kubectl describe node <nome-do-node>

# Ver recursos disponíveis no cluster
kubectl top nodes
```

### Pods e Deployments

```bash
# Listar todos os pods em todos os namespaces
kubectl get pods -A

# Listar pods no namespace default
kubectl get pods

# Listar pods com detalhes (node, IP)
kubectl get pods -o wide

# Descrever um pod (ver eventos, configuração)
kubectl describe pod <nome-do-pod>

# Ver logs de um pod
kubectl logs <nome-do-pod>

# Ver logs em tempo real (follow)
kubectl logs -f <nome-do-pod>

# Ver logs das últimas 100 linhas
kubectl logs <nome-do-pod> --tail=100

# Ver logs do container anterior (se crashou)
kubectl logs <nome-do-pod> --previous

# Listar deployments
kubectl get deployments

# Verificar status de rollout
kubectl rollout status deployment/oficina-api

# Ver histórico de rollout
kubectl rollout history deployment/oficina-api
```

### Services e Networking

```bash
# Listar services
kubectl get services

# Listar services com detalhes (ClusterIP, NodePort)
kubectl get services -o wide

# Descrever um service
kubectl describe service oficina-api

# Ver endpoints
kubectl get endpoints
```

### ConfigMaps e Secrets

```bash
# Listar ConfigMaps
kubectl get configmaps

# Ver conteúdo de um ConfigMap
kubectl describe configmap oficina-api-configmap

# Listar Secrets
kubectl get secrets

# Ver chaves de um Secret (sem valores)
kubectl describe secret oficina-api-secret
```

### HPA (Horizontal Pod Autoscaler)

```bash
# Ver status do HPA
kubectl get hpa

# Detalhes do HPA (métricas atuais vs target)
kubectl describe hpa oficina-api
```

### Troubleshooting

```bash
# Executar shell em um pod (para debug)
kubectl exec -it <nome-do-pod> -- /bin/sh

# Port-forward (acesso local ao pod sem expor publicamente)
kubectl port-forward pod/<nome-do-pod> 8080:8080

# Ver eventos do namespace (útil para debug)
kubectl get events --sort-by=.lastTimestamp

# Ver eventos de um pod específico
kubectl describe pod <nome-do-pod> | grep -A 20 "Events:"

# Forçar deleção de pod (recriar a partir do deployment)
kubectl delete pod <nome-do-pod>
```

---

## Helm

### Repositórios

```bash
# Adicionar repositório New Relic
helm repo add newrelic https://helm-charts.newrelic.com

# Atualizar repositórios
helm repo update

# Listar repositórios
helm repo list
```

### Releases

```bash
# Listar releases instaladas
helm list -A

# Ver status de uma release
helm status newrelic-bundle -n newrelic

# Ver histórico de uma release
helm history newrelic-bundle -n newrelic

# Fazer rollback para versão anterior
helm rollback newrelic-bundle 1 -n newrelic
```

### New Relic Bundle

```bash
# Instalar/atualizar New Relic nri-bundle
helm upgrade --install newrelic-bundle newrelic/nri-bundle \
  --namespace newrelic --create-namespace \
  --set global.licenseKey=<LICENSE_KEY> \
  --set global.cluster=oficina-cluster \
  --set global.region=US \
  --set infrastructure.enabled=true \
  --set ksm.enabled=true \
  --set kubeEvents.enabled=true \
  --set logging.enabled=true

# Verificar pods do New Relic
kubectl get pods -n newrelic
```

---

## Terraform

### Comandos do dia a dia

```bash
# Inicializar (obrigatório após clone ou mudança de provider)
terraform init \
  -backend-config="bucket=bucket-tfstate-1029" \
  -backend-config="key=k8s/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=meu-terraform-state-lock" \
  -backend-config="encrypt=true"

# Visualizar mudanças sem aplicar
terraform plan \
  -var="newrelic_account_id=..." \
  -var="newrelic_api_key=..." \
  -var="newrelic_license_key=..."

# Aplicar as mudanças
terraform apply \
  -var="newrelic_account_id=..." \
  -var="newrelic_api_key=..." \
  -var="newrelic_license_key=..."

# Ver todos os outputs
terraform output

# Ver um output específico (sem aspas)
terraform output -raw ecr_repository_url
terraform output -raw api_gateway_endpoint
terraform output -raw eks_cluster_name

# Listar recursos gerenciados
terraform state list

# Inspecionar um recurso no state
terraform state show module.eks.aws_eks_cluster.this

# Destruir toda a infraestrutura
terraform destroy \
  -var="newrelic_account_id=..." \
  -var="newrelic_api_key=..." \
  -var="newrelic_license_key=..."
```

### Diagnóstico

```bash
# Validar arquivos HCL sem aplicar
terraform validate

# Formatar código (útil antes de commit)
terraform fmt -recursive

# Ver o plano em formato JSON
terraform plan -out=tfplan.bin
terraform show -json tfplan.bin | jq .
```

---

## Cheklist pós-provisionamento

Após `terraform apply`, execute esses comandos para confirmar que tudo está funcionando:

```bash
# 1. EKS acessível
kubectl get nodes

# 2. Obter URL do API Gateway
terraform output -raw api_gateway_endpoint

# 3. Health check externo (antes do deploy da app, retorna 404 — esperado)
curl -s "$(terraform output -raw api_gateway_endpoint)/actuator/health" | jq .

# 4. ECR criados
aws ecr describe-repositories --region us-east-1 \
  --query 'repositories[*].repositoryName' --output table

# 5. Pods New Relic rodando
kubectl get pods -n newrelic
```
