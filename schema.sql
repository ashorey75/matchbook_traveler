CREATE TABLE cities (
  id serial PRIMARY KEY,
  city_name text NOT NULL UNIQUE
  );
  
CREATE TABLE matches (
  id serial PRIMARY KEY,
  location_name text NOT NULL,
  address text NOT NULL,
  neighborhood text NOT NULL,
  custom_matchbook boolean DEFAULT false NOT NULL,
  city_id integer NOT NULL REFERENCES cities (id) ON DELETE CASCADE);
  
CREATE TABLE users (
  username text NOT NULL UNIQUE,
  password text NOT NULL);
  
INSERT INTO cities (city_name)
VALUES
  ('New York City'),
  ('Los Angeles'),
  ('Philadelphia');

INSERT INTO matches (location_name, address, neighborhood, custom_matchbook, city_id)
VALUES 
  ('House of Wax', '445 Albee Sq.', 'Downtown Brooklyn', true, 1 ),
  ('Brooklyn Pub', '689 6th Ave.', 'Park Slope', false, 1 ),
  ('Catbird', '108 N. 7th St.', 'Williamsburg', true, 1 ),
  ('High Dive', '243 5th Ave.', 'Park Slope', true, 1 ),
  ('Dumpling House', 'Walnut St.', 'Graduate City', false, 3 ),
  ('El Vez', '121 S. 13th st.', 'Center City', true, 3 ),
  ('The Place', '15 12th st.', 'Center City', true, 3 ),
  ('Bonchon', '1 11th st.', 'Center City', true, 3 ),
  ('Crate', 'Park Pl', 'Center City', true, 3 ),
  ('Rame', '55 Chestnut st.', 'Center City', true, 3 ),
  ('Pine and co', '121 Pine st.', 'Center City', true, 3 ),
  ('Landmark', '3535 Market st.', 'Center City', true, 3 ),
  ('Parc', '227 S. 18th St.', 'Rittenhouse Square', true, 3 );
  
  INSERT INTO users (username, password)
  VALUES 
    ('admin', 'password');
  
  
