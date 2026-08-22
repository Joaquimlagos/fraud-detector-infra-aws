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
├── dynamodb.tf                    # tabelas users e transactions
├── sqs.tf                          # fila principal + DLQ
├── sns.tf                           # tópico de alertas + assinatura de e-mail
├── providers.tf                      # provider AWS único + versões exigidas
├── variables.tf                       # parâmetros (region, environment, project_name, alert_email)
├── outputs.tf                          # valores expostos após o apply (URLs, ARNs, nomes)
├── terraform.tfvars.example             # modelo para deploy real — copiar para terraform.tfvars
├── local.tfvars.example                  # modelo para uso local — copiar para local.tfvars
└── local_override.tf.example              # modelo do override de provider para LocalStack
docker-compose.localstack.yml         # sobe o LocalStack usado tanto por este repo quanto pelo fraud-detector-lambda
```

## Deploy para AWS real

Pré-requisitos: credenciais AWS configuradas (`aws configure` ou variáveis de ambiente), com permissão para criar DynamoDB, SQS, SNS **e IAM** de forma geral (a Lambda cria sua própria IAM role no repo dela, mas o usuário/role que roda o Terraform precisa poder gerenciar esses serviços).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com seus valores reais (principalmente alert_email)

terraform init
terraform plan -var-file=terraform.tfvars    # leia o plano com atenção antes de aplicar
terraform apply -var-file=terraform.tfvars
```

Depois do apply, confirme a assinatura do SNS — chega um e-mail com link de confirmação, e o alerta só funciona depois de clicado.

⚠️ Certifique-se de que **não existe** `local_override.tf` na pasta antes de rodar isso — a presença desse arquivo redireciona o provider para o LocalStack, mesmo sem querer. Ver a seção abaixo.

## Desenvolvimento local com LocalStack

Todo o Terraform deste repositório roda igual contra o LocalStack ou contra a AWS real — o que muda é só a presença ou ausência do arquivo `local_override.tf`.

```bash
# 1. Sobe o LocalStack
docker compose -f docker-compose.localstack.yml up -d

# 2. Ativa o override do provider (nunca commitado — fica só na sua máquina)
cd terraform
cp local_override.tf.example local_override.tf
cp local.tfvars.example local.tfvars

# 3. Aplica contra o LocalStack
terraform init
terraform apply -var-file=local.tfvars
```

Para voltar a apontar para a AWS real, basta remover `local_override.tf` (o `providers.tf` original volta a valer sozinho).

**Ordem de apply entre repositórios**: este repositório precisa ser aplicado **antes** do `fraud-detector-lambda`, já que a Lambda busca a fila/tabelas/tópico por nome via data source — se eles ainda não existirem, o apply da Lambda falha com um erro claro de "recurso não encontrado".

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
