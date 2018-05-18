/*
 * Clear out the table and start fresh 
 */

DROP DATABASE IF EXISTS osrs;
CREATE DATABASE osrs;

\c osrs
DROP TABLE IF EXISTS items;
CREATE TABLE items (
    item_id INTEGER,
    name TEXT,
    price INTEGER,
    examine TEXT,
    created_date timestamp default current_timestamp
);
