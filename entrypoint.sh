#!/bin/sh
set -e

echo "==> Checking database readiness..."

MAX_RETRIES=20
RETRY_INTERVAL=3
TRIES=0

while ! bundle exec rails db:version > /dev/null 2>&1; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge "$MAX_RETRIES" ]; then
    echo "Database not ready after $((MAX_RETRIES * RETRY_INTERVAL)) seconds. Exiting."
    exit 1
  fi
  echo "Attempted $TRIES/$MAX_RETRIES: Waiting for DB..."
  sleep "$RETRY_INTERVAL"
done

echo "Database is ready."


echo "==> Executing translation:sync..."
if ! bundle exec rake translation:sync; then
  echo "ERROR: translation:sync failed, continuing anyway."
fi


echo "==> Starting Rails server..."
exec bundle exec rails s
