# Observabilidade — New Relic

Este repositório provisiona automaticamente a infraestrutura de observabilidade via Terraform e instala o agente New Relic no cluster EKS via pipeline.

---

## O que é provisionado

| Componente | Como provisionado | Finalidade |
|-----------|------------------|-----------|
| Synthetic Monitor | Terraform (`newrelic_synthetics_monitor`) | Health check externo a cada 2 min |
| Dashboard | Terraform (`newrelic_one_dashboard_json`) | Visualização de métricas da plataforma |
| nri-bundle | Helm (via pipeline Job 3) | Agente de infra + logs + eventos K8s |

---

## Synthetic Monitor

**Nome:** `Ping oficina-api`  
**Tipo:** SIMPLE (HTTP ping)  
**URL monitorada:** `{api_gateway_endpoint}/actuator/health/liveness`  
**Frequência:** A cada 2 minutos  
**Localização:** `AWS_SA_EAST_1` (São Paulo)

O monitor valida a cadeia completa de ponta a ponta:
```
New Relic (externo) → API Gateway → VPC Link → NLB → EKS NodePort → Spring Boot Actuator
```

**Resposta esperada:**
```json
HTTP 200 OK
{ "status": "UP" }
```

---

## Dashboard

O dashboard tem 4 páginas, todas provisionadas via `dashboard.json` no módulo `new_relic`:

### Página 1 — Cluster Overview
- Tráfego de rede (transmit/receive bytes/s)
- Storage usado (%)
- CPU usado (%)
- Memória usada (%)

### Página 2 — Deployment Overview
- Total/disponíveis/indisponíveis/desejados de pods
- Contagem de réplicas ao longo do tempo
- Disponibilidade de réplicas
- Réplicas atualizadas

### Página 3 — Logs
- Volume de logs ao longo do tempo
- Tabela de logs recentes (severity, level, timestamp, message)

### Página 4 — Ordens de Serviço
- Volume de OS criadas por dia (últimos 7 dias)
- Tempo médio de execução por status
- Falhas de integração por HTTP status
- Latência P50/P95/P99 das APIs
- Consumo de CPU por pod
- Falhas de processamento de OS

### Página 5 — Healthcheck
- Tempo de request/response do Synthetic Monitor
- Connection times por resultado
- Error response codes
- Uptime % (última semana)

---

## Agente New Relic no Kubernetes (nri-bundle)

A pipeline instala o `newrelic/nri-bundle` via Helm no namespace `newrelic`:

```bash
helm upgrade --install newrelic-bundle newrelic/nri-bundle \
  --namespace newrelic --create-namespace \
  --set global.licenseKey=<LICENSE_KEY> \
  --set global.cluster=oficina-cluster \
  --set global.region=US \
  --set infrastructure.enabled=true \
  --set ksm.enabled=true \
  --set kubeEvents.enabled=true \
  --set logging.enabled=true
```

**Componentes instalados:**

| Componente | Flag | O que coleta |
|-----------|------|-------------|
| New Relic Infrastructure | `infrastructure.enabled=true` | CPU, memória, disco, rede dos nodes |
| Kube State Metrics | `ksm.enabled=true` | Estado dos deployments, pods, services |
| Kube Events | `kubeEvents.enabled=true` | Eventos do Kubernetes (OOMKill, probe failures) |
| Log Forwarder | `logging.enabled=true` | Logs dos pods → New Relic Logs |

---

## Verificar instalação

```bash
# Ver pods do namespace newrelic
kubectl get pods -n newrelic

# Saída esperada:
# newrelic-bundle-nrk8s-ksm-...        Running
# newrelic-bundle-nrk8s-kubelet-...    Running
# newrelic-bundle-newrelic-logging-... Running
# newrelic-bundle-kube-events-...      Running

# Ver logs do agente de infra
kubectl logs -n newrelic -l app.kubernetes.io/name=newrelic-infrastructure -f
```

---

## Acessar o Dashboard

1. Acesse [New Relic One](https://one.newrelic.com)
2. Menu → **Dashboards**
3. Procure por `Oficina API Dashboard`

Ou via link direto se tiver o GUID do dashboard:
```
https://one.newrelic.com/dashboards/<DASHBOARD_GUID>
```

---

## Acessar o Synthetic Monitor

1. Acesse [New Relic One](https://one.newrelic.com)
2. Menu → **Synthetic Monitoring**
3. Procure por `Ping oficina-api`

---

## Alertas configurados

O `nri-bundle` instala políticas de alertas padrão para:
- Pod não disponível por mais de 5 minutos
- Node com uso de CPU > 90%
- Node com uso de memória > 90%

Para configurar alertas customizados:
1. New Relic → **Alerts & AI** → **Alert Policies**
2. Crie condições NRQL baseadas nos dados do dashboard

**Exemplo de alerta para a OS:**
```sql
SELECT count(*) FROM Log
WHERE message LIKE '%Ordem de serviço criada com sucesso%'
SINCE 5 MINUTES AGO
COMPARE WITH 1 HOUR AGO
```

---

## Credenciais necessárias

| Credencial | Onde usar | Como obter |
|-----------|----------|-----------|
| `NEW_RELIC_LICENSE_KEY` | `terraform -var` + Helm | New Relic → API Keys → tipo **Ingest - License** |
| `NEW_RELIC_API_KEY` | `terraform -var` | New Relic → API Keys → tipo **User** |
| `NEW_RELIC_ACCOUNT_ID` | `terraform -var` | New Relic → canto inferior esquerdo |
