
resource "aws_efs_file_system" "efs-platform" {
  creation_token = "${local.config.cluster_name}"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Template = "Platform_Ec2"
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.efs-platform.id

  backup_policy {
    status = "ENABLED"
  }
}

## Teste access-point efs

resource "aws_efs_access_point" "access-point" {
  file_system_id = aws_efs_file_system.efs-platform.id

  root_directory {
    path = "/platform"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.efs-platform.id
  subnet_id      = local.config.SUBNET_ID
  security_groups = [aws_security_group.web_security_group.id]
}

output "efs_dns_name" {
  value = aws_efs_file_system.efs-platform.dns_name
}