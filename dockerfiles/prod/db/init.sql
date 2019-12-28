CREATE TABLE users (
    id INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(16) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL,
    PRIMARY KEY (id)
) ENGINE='InnoDB';

CREATE TABLE accounts (
    id INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL UNIQUE,
    username VARCHAR(64),
    email VARCHAR(64),
    password VARBINARY(128) NOT NULL,
    PRIMARY KEY (id)
) ENGINE='InnoDB';

INSERT INTO users (username, password) VALUES ('john', 'bcryptHashedPassword');
