## Cloud SQL Tunnel

Creates a SSH tunnel to a GCP CloudSQL instance.
### Setup

Download the `cloud-sql-tunnel.sh` and apply `chmod +x cloud-sql-tunnel.sh`

### Usage:

```bash
cloud-sql-tunnel --conn_name "<project>:<zone>:<db_instance_name>" --project "<project>" --zone "<zone>" --instance "<host_instance_name>"
```
