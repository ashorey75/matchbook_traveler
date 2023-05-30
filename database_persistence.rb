require 'pg'

# Provides interaction with the database
class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'matchbook')
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def check_username(username)
    sql = <<~SQL
      SELECT * FROM users
      WHERE username = $1
    SQL
    result = query(sql, username)
    result.ntuples
  end

  def create_new_user(username, password)
    sql = <<~SQL
      INSERT INTO users (username, password)
      VALUES ($1, $2)
    SQL

    query(sql, username, password)
  end

  def validate_login(username, password)
    sql = <<~SQL
      SELECT * FROM users
      WHERE username = $1 AND password = $2
    SQL
    result = query(sql, username, password)
    result.ntuples
  end
  
  def user_password(username)
    sql = <<~SQL
      SELECT password FROM users
      WHERE username = $1
    SQL
    query(sql, username).first
    
  end
  
  
  def validate_all_cities
    sql = <<~SQL
      SELECT * FROM cities
      ORDER BY city_name
    SQL
    result = query(sql)

    result.map { |tuple| tuple_to_list_hash(tuple) }
  end
  
  def all_cities(page)
    sql = <<~SQL
      SELECT * FROM cities
      ORDER BY city_name
      LIMIT 10
      OFFSET ($1 * 10)
    SQL
    result = query(sql, page)

    result.map { |tuple| tuple_to_list_hash(tuple) }
  end

  def location_count(city_id)
    sql = <<~SQL
      SELECT * FROM matches
      WHERE city_id = $1
    SQL

    result = query(sql, city_id)

    result.ntuples
  end

  def city_count
    sql = <<~SQL
      SELECT * FROM cities
    SQL

    result = query(sql)

    result.ntuples
  end

  def find_city(id)
    sql = <<~SQL
      SELECT * FROM cities
      WHERE id = $1
    SQL
    result = query(sql, id).first
    tuple_to_list_hash(result)
  end

  def all_city_id
    sql = <<~SQL
      SELECT id FROM cities
    SQL
    query(sql)
  end

  def all_match_id
    sql = <<~SQL
      SELECT id FROM matches
    SQL
    query(sql)
  end
  
  def count_city_matches(city_id)
    sql = <<~SQL
      SELECT * FROM matches
      WHERE city_id = $1
    SQL
    query(sql, city_id)
  end

  def add_city(city_name)
    sql = <<~SQL
      INSERT INTO cities(city_name)
      VALUES ($1)
    SQL
    query(sql, city_name)
  end

  def delete_city(id)
    sql = <<~SQL
      DELETE FROM cities
      WHERE id = $1
    SQL
    query(sql, id)
  end

  def update_city_name(id, city_name)
    sql = <<~SQL
      UPDATE cities
      SET city_name = $2
      WHERE id = $1
    SQL
    query(sql, id, city_name)
  end

  def match_locations(id, page)
    sql = <<~SQL
      SELECT matches.* FROM matches
      JOIN cities ON cities.id = matches.city_id WHERE city_id = $1
      ORDER BY neighborhood, location_name
      LIMIT 10
      OFFSET ($2 * 10)
    SQL
    result = query(sql, id, page)

    result.map { |tuple| tuple_to_list_hash(tuple) }
  end

  def find_match_location(match_id)
    sql = <<~SQL
      SELECT * FROM matches
      WHERE id = $1
    SQL
    result = query(sql, match_id).first

    tuple_to_list_hash(result)
  end

  def add_match_location(location_name, address, custom_matchbook, neighborhood, id)
    sql = <<~SQL
      INSERT INTO matches(location_name, address, custom_matchbook, neighborhood, city_id)
      VALUES ($1, $2, $3, $4, $5)
    SQL
    query(sql, location_name, address, custom_matchbook, neighborhood, id)
  end

  def update_match_location(location_name, address, custom_matchbook, neighborhood, match_id)
    sql = <<~SQL
      UPDATE matches
      SET location_name = $1,
          address = $2,
          custom_matchbook = $3,
          neighborhood = $4
      WHERE id = $5
    SQL
    query(sql, location_name, address, custom_matchbook, neighborhood, match_id)
  end

  def delete_match_location(id, match_id)
    sql = <<~SQL
      DELETE FROM matches
      WHERE city_id = $1
      AND id = $2
    SQL
    query(sql, id, match_id)
  end

  def tuple_to_list_hash(tuple)
    {
      id: tuple['id'].to_i,
      city_name: tuple['city_name'],
      location_name: tuple['location_name'],
      address: tuple['address'],
      custom_matchbook: tuple['custom_matchbook'],
      neighborhood: tuple['neighborhood']
    }
  end
end
