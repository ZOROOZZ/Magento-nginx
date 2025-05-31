#!/bin/bash

set -e

# Load .env if exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Prompt for Magento Marketplace keys if missing
if [ -z "$MAGENTO_PUBLIC_KEY" ]; then
  read -p "Enter Magento Public Key: " MAGENTO_PUBLIC_KEY
fi

if [ -z "$MAGENTO_PRIVATE_KEY" ]; then
  read -sp "Enter Magento Private Key: " MAGENTO_PRIVATE_KEY
  echo
fi

# Check required environment variables
required_vars=(
  DB_HOST
  DB_NAME
  DB_USER
  DB_PASSWORD
  BASE_URL
  ADMIN_FIRSTNAME
  ADMIN_LASTNAME
  ADMIN_EMAIL
  ADMIN_USERNAME
  ADMIN_PASSWORD
  SEARCH_ENGINE
  ELASTICSEARCH_HOST
  ELASTICSEARCH_PORT
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo " Required variable $var is missing or empty in .env"
    exit 1
  fi
done

# Wait for MySQL in the Docker network
echo "Waiting for MySQL ($DB_HOST) to be available on port 3306..."

until docker exec magento-php bash -c "nc -z $DB_HOST 3306"; do
  echo "Waiting for MySQL..."
  sleep 3
done

echo "MySQL is available. Proceeding..."

# Configure Composer Authentication inside magento-php container
echo "Configuring composer authentication inside container..."
docker exec magento-php composer config --global http-basic.repo.magento.com "$MAGENTO_PUBLIC_KEY" "$MAGENTO_PRIVATE_KEY"

# Remove previous Magento installation to start fresh
echo "Removing previous Magento installation from /var/www/html ..."
docker exec magento-php bash -c "rm -rf /var/www/html/* /var/www/html/.[!.]* || true"

echo "Installing Magento inside container..."

# Create Magento project fresh
docker exec magento-php composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html

echo "Running Magento setup install inside container..."

docker exec magento-php php /var/www/html/bin/magento setup:install \
  --base-url="$BASE_URL" \
  --db-host="$DB_HOST" \
  --db-name="$DB_NAME" \
  --db-user="$DB_USER" \
  --db-password="$DB_PASSWORD" \
  --admin-firstname="$ADMIN_FIRSTNAME" \
  --admin-lastname="$ADMIN_LASTNAME" \
  --admin-email="$ADMIN_EMAIL" \
  --admin-user="$ADMIN_USERNAME" \
  --admin-password="$ADMIN_PASSWORD" \
  --language=en_US \
  --currency=USD \
  --timezone=Asia/Kolkata \
  --use-rewrites=1 \
  --search-engine="$SEARCH_ENGINE" \
  --elasticsearch-host="$ELASTICSEARCH_HOST" \
  --elasticsearch-port="$ELASTICSEARCH_PORT"

echo "Magento installation complete."

echo "Setting file permissions inside container..."
docker exec magento-php bash -c "find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +"
docker exec magento-php bash -c "find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"
docker exec magento-php chown -R www-data:www-data /var/www/html

echo "Disabling Two-Factor Authentication modules..."
docker exec -u www-data -w /var/www/html magento-php php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth
docker exec -u www-data -w /var/www/html magento-php php bin/magento module:disable Magento_TwoFactorAuth
echo "Two-Factor Authentication disabled."

echo "Cleaning cache and deploying static content inside container..."
docker exec magento-php php /var/www/html/bin/magento cache:clean
docker exec magento-php php /var/www/html/bin/magento setup:di:compile
docker exec magento-php php /var/www/html/bin/magento setup:static-content:deploy -f

echo "Magento setup finished successfully."
echo "Fetching Magento Admin URL..."

ADMIN_URI=$(docker exec -u www-data -w /var/www/html magento-php php bin/magento info:adminuri 2>/dev/null | grep '^Admin URI:' | awk '{print $3}')
if [ -n "$ADMIN_URI" ]; then
  echo "Admin Panel URL: ${BASE_URL%/}$ADMIN_URI"
else
  echo "Could not fetch Admin URI."
fi