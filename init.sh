#!/bin/bash

echo "Running SQL script..."
mysql -u root -prootpassword mydb < /docker-entrypoint-initdb.d/PerformanceComplete.sql
