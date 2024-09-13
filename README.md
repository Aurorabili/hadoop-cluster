# Mini Hadoop Cluster in Docker

This project is a mini hadoop cluster in docker, including one master and two slaves.

## 🚀 Quick Start

### Clone the project

```bash
git clone https://github.com/Aurorabili/hadoop-cluster
```

### Build the docker image

```bash
cd hadoop-cluster
docker compose build
```

### Start the cluster

```bash
docker compose up -d
```

### Access Web UI

- Hadoop: [http://localhost:39870](http://localhost:39870)
- YARN: [http://localhost:38088](http://localhost:38088)

## Use SSH

All nodes have SSH service but it is not running by default. You can start it by running the following command:

```bash
docker exec -it ${container-hash} sudo service ssh start
```
