#!/bin/bash

# used for the pg_trgm extension, for fuzzy string matching
sudo apt install postgresql-contrib

su postgres -c "psql -f schema.sql"
