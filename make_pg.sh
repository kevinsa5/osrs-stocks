#!/bin/bash

su postgres -c "psql -f schema.sql"
