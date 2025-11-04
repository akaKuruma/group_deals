#!/bin/bash

# Create docker volumes
docker volume create group_deals_postgres_data
docker volume create group_deals_data
docker network create group_deals_network