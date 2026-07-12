#!/bin/bash
# ============================================================
# Instala y configura el CloudWatch Agent como servicio systemd
# independiente de Docker: si el agente no logra escribir en
# CloudWatch Logs (permisos faltantes en el rol de la instancia),
# los contenedores de la aplicacion siguen corriendo igual, ya que
# el agente no participa en el arranque de los contenedores.
# ============================================================
set -eux

dnf install -y amazon-cloudwatch-agent

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'CWCONFIG'
{
  "agent": {
    "region": "${region}",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*-json.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "${log_stream_name}-{instance_id}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

systemctl enable amazon-cloudwatch-agent || true
