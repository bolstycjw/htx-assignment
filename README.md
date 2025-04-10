# Automatic Speech Recognition (ASR) with Search System


## Project Structure

```
.
├── asr/                        # ASR microservice directory
│   ├── asr_api.py              # FastAPI implementation for ASR
│   ├── cv-decode.py            # Script to process Common Voice dataset
│   ├── Dockerfile              # Docker configuration for ASR service
│   ├── docker-compose.yml      # Docker Compose for local deployment
│   └── requirements.txt        # ASR-specific dependencies
├── elastic-backend/            # Elasticsearch backend services
│   ├── cv-index.py             # Script to index Common Voice data in Elasticsearch
│   ├── docker-compose.yml      # Docker Compose for Elasticsearch and Kibana
│   └── config/                 # Elasticsearch configuration files
├── search-ui/                  # Search UI frontend application
│   ├── src/                    # React source code
│   ├── public/                 # Static assets
│   ├── Dockerfile              # Docker configuration for Search UI
│   ├── docker-compose.yml      # Docker Compose for local deployment
│   ├── package.json            # NPM dependencies
├── infra/                      # Infrastructure as Code (Terraform)
│   ├── ec2.tf                  # EC2 instance definitions
│   ├── vpc.tf                  # VPC network configuration
│   ├── security.tf             # Security groups and rules
│   ├── outputs.tf              # Terraform outputs
│   ├── *_setup.sh              # Service setup scripts
├── deployment-design/          # Deployment architecture documentation
│   └── design.pdf              # AWS deployment architecture
├── cv-valid-dev/               # Common Voice dataset directory
├── requirements.txt            # Python dependencies
├── .gitignore                  # Git ignore file
└── README.md                   # This file
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/bolstycjw/htx-assignment
cd htx-assignment
```

### 2. Set Up Virtual Environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Running the System Locally

### ASR API

```bash
cd asr
docker-compose up -d
```

The ASR API will be available at http://localhost:8001/

### Elasticsearch and Kibana

```bash
cd elastic-backend
docker-compose up -d
```

Elasticsearch will be available at http://localhost:9200/
Kibana will be available at http://localhost:5601/

### Search UI

```bash
cd search-ui
docker-compose up -d
```

The Search UI will be available at http://localhost:3000/

## Using the ASR API

### Test the Ping Endpoint

```bash
curl http://localhost:8001/ping
```

### Transcribe an Audio File

```bash
curl -F 'file=@/path/to/audio.mp3' http://localhost:8001/asr
```

## Processing and Indexing the Common Voice Dataset

After setting up the ASR API and Elasticsearch:

1. Process the Common Voice dataset:
```bash
cd asr
python cv-decode.py [--host API_HOST]
```

Available arguments:
- `--host`: API host address (default: http://localhost:8001)

Examples:
```bash
# Use local API
python cv-decode.py

# Use remote API
python cv-decode.py --host http://18.138.221.204:8001
```

2. Index the processed data in Elasticsearch:
```bash
cd elastic-backend
python cv-index.py [--es-host ES_HOST]
```

Available arguments:
- `--es-host`: Elasticsearch host URL (default: http://localhost:9200)

Examples:
```bash
# Use local API
python cv-index.py

# Use remote API
python cv-index.py --es-host http://18.142.126.205:9200
```

## Infrastructure Deployment

For deploying to AWS infrastructure:
```bash
cd infra
terraform init
terraform apply
```

## Deployment Endpoints

| Service | Endpoint |
|---------|----------|
| Elasticsearch | http://18.142.126.205:9200 |
| Kibana | http://18.142.126.205:5601 |
| Search UI | http://13.250.218.11:3000 |
| ASR API | http://18.138.221.204:8001 |