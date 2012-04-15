BEGIN;

CREATE TABLE networks (
  id SERIAL PRIMARY KEY,
  parent integer references networks(id),
  address_range cidr UNIQUE NOT NULL,
  description text,
  subdivide boolean NOT NULL,
  valid_masks smallint[],
  owner character varying(255),
  account character varying(32),
  service integer
);

CREATE TABLE hosts (
  address inet PRIMARY KEY,
  network integer references networks(id) NOT NULL,
  description text NOT NULL
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username character varying(32) UNIQUE NOT NULL,
  password text NOT NULL,
  email text,
  status integer DEFAULT 1 NOT NULL
);

CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name character varying(255) UNIQUE NOT NULL
);

CREATE TABLE user_roles (
  "user" INTEGER REFERENCES users(id) NOT NULL,
  role INTEGER REFERENCES roles(id) NOT NULL,
  PRIMARY KEY ("user", role)
);

CREATE TABLE changelog (
  id SERIAL PRIMARY KEY,
  "user" INTEGER REFERENCES users(id) NOT NULL,
  change_time timestamp DEFAULT now() NOT NULL,
  prefix inet NOT NULL,
  change text NOT NULL
);

INSERT INTO roles ("name") VALUES ('administrator');
INSERT INTO roles ("name") VALUES ('creator');
INSERT INTO roles ("name") VALUES ('editor');
INSERT INTO roles ("name") VALUES ('reader');

COMMIT;
