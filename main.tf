### DATA IMPORT
data "aws_ami" "amazon-linux" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    # values = ["amzn2-ami-hvm-*-x86_64-ebs"]
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_route53_zone" "selected" {
  name         = "${local.config.domain}"
  private_zone = false
}

### RESOURCES

resource "aws_security_group" "web_security_group" {
  name        = "access_cluster_${local.config.cluster_name}_SG"
  description = "Allow SSH and HTTP"
  vpc_id      = local.config.VPC_ID
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "Cluster Access"
    from_port   = 6550
    to_port     = 6550
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
  Template = "Platform_Ec2"
  }
}

resource "aws_instance" "platform-vm" {
  ami             = data.aws_ami.amazon-linux.id
  key_name        = local.config.keypair
  security_groups = [aws_security_group.web_security_group.id]
  instance_type   = local.config.instance_type
  subnet_id       = local.config.SUBNET_ID
  user_data = <<EOF
#!/bin/bash
sudo yum update && sudo yum upgrade
sudo yum install -y curl-minimal wget openssl git unzip docker sed
sudo service docker start && sudo systemctl enable docker.service
sudo usermod -a -G docker ec2-user && newgrp docker
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
curl -sS https://webinstall.dev/k9s | bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.7/2023-11-02/bin/linux/amd64/kubectl
chmod +x ./kubectl && mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
k3d cluster create ${local.config.cluster_name} --servers 1 -p "80:80@loadbalancer" -p "443:443@loadbalancer" --api-port 6550  --k3s-arg "--disable=traefik@server:*" --kubeconfig-update-default
sleep 2

helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --create-namespace -n metallb-system --wait
sleep 2

export TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export EC2_PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
echo "IP_EC2 = $EC2_PUBLIC_IP"

echo "
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - $EC2_PUBLIC_IP/32
" | kubectl apply -f -

mkdir /home/ec2-user/.kube && k3d kubeconfig get ${local.config.cluster_name} > /home/ec2-user/.kube/config

EOF

  root_block_device {
    volume_size = local.config.volume_size
  }

  tags = {
    Name = local.config.cluster_name
  }
}

resource "aws_eip" "webip" {
    vpc = true
    tags = {
    Name = "${local.config.cluster_name}-platform-eip"
    Template = "Platform_Ec2"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.platform-vm.id
  allocation_id = aws_eip.webip.id
}

resource "aws_route53_record" "sub_domain_wildcard" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "*.${local.config.cluster_name}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.webip.public_ip}"]
}

resource "aws_route53_record" "sub_domain" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.config.cluster_name}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.webip.public_ip}"]
}

### OUTPUT

output "instance_ip_addr" {
  value       = aws_eip.webip.public_ip
}