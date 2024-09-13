# Mini Hadoop Cluster in Docker

This project is a mini hadoop cluster in docker, including one master and two slaves.

## 🍪 How to use

### 1. Clone the project

```bash
git clone https://github.com/Aurorabili/hadoop-cluster
```

### 2. Build the docker image

```bash
cd hadoop-cluster
docker compose build
```

### 3. Start the cluster

```bash
docker compose up -d
```

### 4. Access Web UI

- Hadoop: [http://localhost:39870](http://localhost:39870)
- YARN: [http://localhost:38088](http://localhost:38088)
