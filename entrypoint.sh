#!/bin/sh
set -e

echo "==> Checking database readiness..."
# Although this loop may run indefinitely, Kubernetes readiness probes
# will detect when the app isn't ready and handle pod restarts if needed.
until bundle exec rails db:version; do
  echo "Waiting for DB connection..."
  sleep 3
done

echo "Database is ready."


echo "==> Executing translation:sync..."
if ! bundle exec rake translation:sync; then
  echo "ERROR: translation:sync failed, continuing anyway."
fi


echo "==> Starting Rails server..."
exec bundle exec rails s
