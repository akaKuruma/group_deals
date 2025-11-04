#!/bin/sh
set -e

echo 'Waiting for database...'
until pg_isready -h db -U postgres; do 
  sleep 2
done

echo 'Running migrations...'
/app/bin/group_deals eval 'GroupDeals.Release.migrate()'

echo 'Starting application...'
exec /app/bin/group_deals start