# fraud-detector-infra-aws

Infraestrutura como código (Terraform) para os recursos AWS compartilhados do sistema **fraud-detector** — um projeto de portfólio demonstrando Java + AWS + arquitetura orientada a eventos + processamento assíncrono + persistência NoSQL + notificações desacopladas.

## Onde este repositório se encaixa

O sistema é dividido em três repositórios:

| Repositório | Responsabilidade |
|---|---|
| `fraud-detector-api` | API Java/Spring Boot. Valida transações e publica no SQS. **Nunca** decide se uma transação é suspeita. |
| `fraud-detector-lambda` | Consome a fila SQS, consulta o histórico do usuário no DynamoDB, aplica as regras de fraude, persiste o resultado e publica um alerta no SNS quando suspeita. |
| **`fraud-detector-infra-aws`** (este repositório) | Terraform da infraestrutura compartilhada: tabelas DynamoDB, fila SQS, tópico SNS. |

Este repositório **não contém** a infraestrutura específica da Lambda (IAM role, função, trigger) — isso vive no próprio repositório `fraud-detector-lambda`, que referencia os recursos daqui por nome via Terraform data sources. Ver o `README.md` daquele repo para detalhes.

## O que este repositório cria

- **DynamoDB** — tabela `users` (chave `userId`) e tabela `transactions` (chave `transactionId`, com GSI `userId-occurredAt-index` para consultas de histórico por usuário/janela de tempo)
- **SQS** — fila `transaction-queue` + dead letter queue, com redrive automático após 3 tentativas
- **SNS** — tópico `fraud-alerts`, com uma assinatura de e-mail configurável

## Estrutura

```
terraform/
├── dynamodb.tf
├── sqs.tf
├── sns.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── local.tfvars.example
└── local_override.tf.example
docker-compose.localstack.yml
```

## Deploy para AWS real

Pré-requisitos: credenciais AWS configuradas (`aws configure` ou variáveis de ambiente), com permissão para criar DynamoDB, SQS, SNS **e IAM** de forma geral (a Lambda cria sua própria IAM role no repo dela, mas o usuário/role que roda o Terraform precisa poder gerenciar esses serviços).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Depois do apply, confirme a assinatura do SNS — chega um e-mail com link de confirmação, e o alerta só funciona depois de clicado.

⚠️ Certifique-se de que **não existe** `local_override.tf` na pasta antes de rodar isso — a presença desse arquivo redireciona o provider para o LocalStack, mesmo sem querer. Ver a seção abaixo.

## Desenvolvimento local com LocalStack

O ambiente local executa o Terraform contra o LocalStack, sem criar recursos na sua conta AWS. O arquivo `local_override.tf` redireciona os serviços para `http://localhost:4566` e usa credenciais fictícias aceitas pelo LocalStack.

### Pré-requisitos

- Docker Desktop em execução, com suporte ao Docker Compose
- Terraform `>= 1.7`
- Git, para clonar o repositório

Não é necessário configurar credenciais AWS para executar o ambiente local.

### Subir a infraestrutura

Na raiz do repositório, inicie o LocalStack:

```bash
docker compose -f docker-compose.localstack.yml up -d
```

Confirme que o container está saudável:

```bash
docker compose -f docker-compose.localstack.yml ps
curl http://localhost:4566/_localstack/health
```

Depois, crie os arquivos locais a partir dos exemplos e aplique a infraestrutura:

```bash
cd terraform
cp local_override.tf.example local_override.tf
cp local.tfvars.example local.tfvars

terraform init
terraform validate
terraform plan -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

No PowerShell, os comandos de cópia equivalentes são:

```powershell
Copy-Item local_override.tf.example local_override.tf
Copy-Item local.tfvars.example local.tfvars
```

Os arquivos `local_override.tf`, `local.tfvars`, o state do Terraform e os dados do LocalStack são locais e já estão protegidos pelo `.gitignore`. Nunca preencha arquivos `.example` com credenciais ou e-mails reais antes de publicá-los.

### Conferir os recursos

Após o `apply`, consulte os outputs gerados pelo Terraform:

```bash
terraform output
terraform output transaction_queue_url
terraform output users_table_name
terraform output transactions_table_name
terraform output fraud_alerts_topic_arn
```

Também é possível verificar os serviços diretamente no LocalStack usando a AWS CLI com credenciais fictícias:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws dynamodb list-tables --endpoint-url=http://localhost:4566
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws sqs list-queues --endpoint-url=http://localhost:4566
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws sns list-topics --endpoint-url=http://localhost:4566
```

### Parar e recriar

Para remover os recursos Terraform e parar o LocalStack:

```bash
terraform destroy -var-file=local.tfvars
cd ..
docker compose -f docker-compose.localstack.yml down
```

Para apagar também os dados persistidos pelo LocalStack, remova a pasta `.localstack/` depois de parar o container. Na próxima execução, o ambiente será criado do zero.

Para voltar a apontar para a AWS real, remova `local_override.tf` antes de executar o Terraform. Use o fluxo de deploy da seção anterior e nunca execute `terraform apply` com o override local presente.

**Ordem de apply entre repositórios**: este repositório precisa ser aplicado **antes** do `fraud-detector-lambda`, já que a Lambda busca a fila, as tabelas e o tópico por nome via data source. Se eles ainda não existirem, o apply da Lambda falha com um erro de recurso não encontrado.

## Variáveis

| Variável | Descrição | Obrigatória |
|---|---|---|
| `aws_region` | Região AWS | Não (default `us-east-1`) |
| `environment` | `dev` ou `prod` | Sim |
| `project_name` | Prefixo usado em todos os nomes de recurso | Não (default `fraud-detector`) |
| `alert_email` | E-mail que recebe os alertas de fraude | Sim |

`project_name` e `environment` **precisam ser idênticos** aos usados no `fraud-detector-lambda` — é assim que os data sources daquele repositório encontram os recursos criados aqui.

## Outputs

Depois do apply, use `terraform output` para pegar os valores que a API e a Lambda precisam configurar (URL da fila, nomes das tabelas, ARN do tópico):

```bash
terraform output transaction_queue_url
terraform output users_table_name
terraform output transactions_table_name
terraform output fraud_alerts_topic_arn
```

## Sobre o `.gitignore`

`*.tfvars` (exceto os `.example`), `local_override.tf` (exceto o `.example`) e o state (`*.tfstate*`) nunca são commitados — todos contêm valores sensíveis ou específicos da sua máquina (e-mail real, credenciais, estado da infra provisionada). Só os arquivos `.example` são versionados, servindo de modelo para qualquer pessoa (inclusive você, depois de um tempo) saber o que precisa preencher.
