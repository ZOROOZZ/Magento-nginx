# 🧱 Magento 2 Docker Setup

This repository provides a Dockerized setup to run Magento 2 with a single command. It uses Docker Compose for managing containers and includes a `setup.sh` script for automated installation.

---

## 📦 Stack

- Magento 2 (Community Edition)
- Nginx
- MySQL 8
- Elasticsearch
- Composer

---

## 🚀 Quick Start

## 1. Clone the Repository
```bash
git clone https://github.com/ZOROOZZ/Magento-nginx
cd Magento
```
---

## 2.Configure Credentials via .env File
You can securely configure and manage your Magento project credentials by modifying the ```.env```file. This includes database access, admin account details, and allowing you to customize your environment without altering the main setup script.
```bash
DB_HOST=mysql
DB_NAME=magento
DB_USER=root
DB_PASSWORD=root

BASE_URL=http://localhost/
ADMIN_FIRSTNAME=Admin
ADMIN_LASTNAME=User
ADMIN_EMAIL=admin@example.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Admin123!

SEARCH_ENGINE=elasticsearch8
ELASTICSEARCH_HOST=elasticsearch
ELASTICSEARCH_PORT=9200
```
---
## 3. Start and Set Up Magento
### To build and start containers, then run the Magento setup script:
🧾 Notes
First-time setup requires Magento authentication keys.
``` bash
docker-compose up -d --build
bash setup.sh
docker-compose up nginx
```
Magento will be accessible at: http://localhost/
---
### 📁 Directory Structure
```bash
.
├── Dockerfile
├── docker-compose.yml
├── setup.sh
├── .env
└── magento/       # Magento files will be installed here
```
---
## 👨‍💻 Maintainer
### Mehul Saini

---

