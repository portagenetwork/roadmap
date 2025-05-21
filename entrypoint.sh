#!/bin/sh
set -e

echo "==> Executing translation:sync..."
bundle exec rake translation:sync

echo "==> Starting Rails server..."
exec bundle exec rails s
