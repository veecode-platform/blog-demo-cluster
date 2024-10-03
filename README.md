# GitOps | Amazon Web Services - Cluster Ec2

O projeto GitOps é um template para provisionamento do cluster em Ec2 na AWS.

## Como usar

Após ser realizado o clone do repositório é necessário a configuração de três variável de ambiente no repositório, sendo elas: `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` e `AWS_REGION`. Essas variável são o Access Key ID, Secret Access Key e a Região da AWS. Para saber como criar as chaves acesse a [documentação oficial](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

Com as variáveis de ambiente definida no repositório já é possível executar a pipeline para provisionamento do cluster EKS, porém há uma configuração padrão de provisionamento localizada em [config/defaults.yml](config/defaults.yml) que pode ser alterada de acordo com a necessidade do usuário.

### Pipeline

A pipeline é dividia em 2 workflows, sendo eles:
  - **Deploy:** Provisiona a infraestrutura via Terraform.
  - **Destroy (execução manual):** Destrói a infraestrutura.

