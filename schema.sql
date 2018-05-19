/*
 * Clear out the table and start fresh 
 */

DROP DATABASE IF EXISTS osrs;
CREATE DATABASE osrs;

\c osrs

CREATE EXTENSION pg_trgm;

DROP TABLE IF EXISTS items;
CREATE TABLE items (
    item_id INTEGER,
    name TEXT,
    price INTEGER,
    examine TEXT,
    icon BYTEA,
    created_date timestamp default current_timestamp
);
