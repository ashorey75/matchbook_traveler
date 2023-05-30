require 'sinatra'
require 'sinatra/content_for'
require 'bundler/setup'
require 'tilt/erubis'
require 'bcrypt'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, 'qtyW1w7JxpkHVhUHGRtqQ35qFdHmLW8QuUyXiYvFSYnpRkvpU4oO5AksBlai7AIJ'
  set :erb, escape_html: true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end
helpers do
  # Converts true boolean value into string to be displayed
  def custom_match?(string)
    return 'Custom matchbooks' unless string == 'f'
  end

  def true_or_false?(boolean)
    boolean.to_s == 't' ? 'True' : 'False'
  end
end

# Returns error for invalid username
def error_for_username(username)
  if username != username.gsub(/\s+/, '')
    'Usernames with spaces are invalid'
  elsif @storage.check_username(username).positive?
    'This username already exists'
  elsif username.size < 4 || username.size > 25
    'Username should be between 8 and 25 characters long'
  end
end

# Returns the error message for invalid spaces and character size
def error_for_password(password)
  if password != password.gsub(/\s+/, '')
    'Passwords with spaces are invalid'
  elsif password.size < 8 || password.size > 25
    'Passwords should be between 8 and 25 characters long'
  end
end

# Returns error for invalid char size and non unique names
def validate_city_name(city_name)
  if !(1..50).cover? city_name.size
    'City name must be between 1 and 50 characters.'
  elsif @storage.validate_all_cities.any? { |city| city[:city_name] == city_name }
    'City name must be unique.'
  end
end

# Returns error for invalid match location data
def validate_match_location(location_name, address, custom_matchbook, neighborhood)
  if !(1..50).cover? location_name.size
    'Location name must be between 1 and 50 characters'
  elsif !(1..50).cover? address.size
    'Address name must be between 1 and 50 characters'
  elsif !(1..50).cover? neighborhood.size
    'Neighborhood must be between 1 and 50 characters'
  elsif custom_matchbook != 'false' && custom_matchbook != 'true'
    'Custom machbook must be True or False'
  end
end

def validate_login(hashed_pass, input_password)
  BCrypt::Password.new(hashed_pass) == input_password 
end

# Strips user input of extra whitespace and capitalized the first letter of each word
def cap_format(string)
  string_array = string.strip.split(' ')
  string_array.map(&:capitalize).join(' ')
end

# Validates if given id parameter exists in the database
def validate_id_params(all_id, id)
  all_id.values.include?([id])
end

not_found do
  status 404
  'Error 404. Page not found'
end

# Allows user to create a username and password by displaying sign up form
get '/new_user' do
  erb :new_user
end

# Submits form and creates user credentials, reroutes to login page
post '/new_user' do
  username = params[:username]
  password = params[:password]
  user_error = error_for_username(username)
  pass_error = error_for_password(password)
  if user_error
    session[:error] = user_error
    erb :new_user
  elsif pass_error
    session[:error] = pass_error
    erb :new_user
  else
    hashed_pass = BCrypt::Password.create(password)
    @storage.create_new_user(username, hashed_pass)

    session[:success] = 'User created successfully'
    redirect '/login'

  end
end

# Displays login page
get '/login' do
  erb :login
end

# Submits login form and reroutes to main 'cities' page
post '/login' do
  username = params[:username]
  password = params[:password]
  
  if @storage.user_password(username)
    hashed_pass = @storage.user_password(username)['password']
    
    # Check if the username and password are correct with method on DataPersistance page
    if validate_login(hashed_pass, password)
      session[:user] = username
      redirect(session.delete(:return_to) || '/cities')
    else
      session[:error] = 'invalid username and/or password'
      erb :login
    end
  
  else
    session[:error] = 'invalid username and/or password'
    erb :login
  end
end

# Submits logout form and redirects to the login page
post '/logout' do
  session.clear
  redirect '/login'
end

# Brings user to the main page, 'cities'
get '/' do
  redirect '/cities'
end

# main user page that displays stored cities
get '/cities' do
  if session[:user]
    
    page = params[:page]
    if page.nil? || page.to_i.positive? || page == '0'
      @page = page.to_i || 1
      
      @total_cities = @storage.city_count
  
      if @page * 10 < @total_cities
        @cities = @storage.all_cities(@page)
  
        erb :cities
      else
        status 404
        session[:error] = 'Invalid Page Number'
        redirect '/cities'
      end
    else
      status 404
      session[:error] = 'Page number must be a positive numerical'
      redirect '/cities'
    end
  else
    redirect '/login'
  end
end

# Displays form page to enter a new city
get '/add_city' do
  session[:return_to] = request.path_info

  if session[:user]
    erb :add_city
  else
    redirect '/login'
  end
end

# Submits form, adds new city, and reroutes to main page
post '/cities' do
  city_name = cap_format(params[:city_name])

  error = validate_city_name(city_name)
  if error
    session[:error] = error
    erb :add_city
  else
    @storage.add_city(city_name)
    session[:success] = "#{city_name} has been added!"
    redirect '/cities'
  end
end

# Displays selected city as well as related match locations
get '/cities/:id' do
  @city_id = params[:id]
  @all_ids = @storage.all_city_id
  session[:return_to] = request.path_info

  if session[:user]
    if validate_id_params(@all_ids, @city_id)
      page = params[:page]
      if  page.nil? || page.to_i.positive? || page == '0'

        @page = params[:page].to_i || 1
        @total_locations = @storage.location_count(@city_id)
        if @page * 10 < @total_locations || @total_locations == 0
          @city = @storage.find_city(@city_id)
          @locations = @storage.match_locations(@city_id, @page)
          erb :city
        elsif @total_locations == 0
          'No pages available'
        else
          status 404
          session[:error] = 'Invalid Page Number'
          redirect "/cities/#{@city_id}"
        end
      else
        status 404
        session[:error] = 'Page number must be a positive numerical'
        redirect "/cities/#{@city_id}"
      end
    else
      status 404
      session[:error] = 'Invalid city ID'
      redirect '/cities'

    end
  else
    redirect '/login'
  end
end

# Deletes selected city
post '/cities/:id/delete_city' do
  id = params[:id]
  session[:success] = "#{@storage.find_city(id)[:city_name]} has been deleted"
  @storage.delete_city(id)

  redirect '/cities'
end

# Displays page for city name edit
get '/cities/:id/edit' do
  @city_id = params[:id]
  @all_ids = @storage.all_city_id
  session[:return_to] = request.path_info

  if session[:user]
    if validate_id_params(@all_ids, @city_id)
      @city = @storage.find_city(@city_id)
      erb :edit_city
    else
      status 404
      session[:error] = 'Invalid city ID'
      redirect '/cities'
    end
  else
    redirect '/login'
  end
end

# Edit the current city name
post '/cities/:id/edit' do
  @city = @storage.find_city(params[:id])
  city_name = cap_format(params[:city_name])
  error = validate_city_name(city_name)
  if error
    session[:error] = error
    erb :edit_city
  else
    id = params[:id]
    @storage.update_city_name(id, city_name)
    session[:success] = 'The city name has been updated!'
    redirect "/cities/#{id}"
  end
end

# Add a match location to the current city
get '/cities/:id/match_location/add' do
  session[:return_to] = request.path_info

  if session[:user]
    @city_id = params[:id]
    @all_city_ids = @storage.all_city_id
    if validate_id_params(@all_city_ids, @city_id)
      @city = @storage.find_city(@city_id)
      erb :add_location
    else
      status 404
      session[:error] = 'Invalid city ID'
      redirect '/cities'
    end
  else
    redirect '/login'
  end
end

post '/cities/:id/match_location/add' do
  @city = @storage.find_city(params[:id])

  location_name = cap_format(params[:location_name])
  address = cap_format(params[:address])
  custom_matchbook = params[:custom_matchbook].downcase
  neighborhood = cap_format(params[:neighborhood])

  error = validate_match_location(location_name, address, custom_matchbook, neighborhood)
  if error
    session[:error] = error
    erb :add_location
  else
    id = params[:id]
    @storage.add_match_location(location_name, address, custom_matchbook, neighborhood, id)
    redirect "cities/#{id}"
  end
end

# View of given match location
get '/cities/:id/match_locations/:match_id' do
  @city_id = params[:id]
  @match_id = params[:match_id]
  @all_city_ids = @storage.all_city_id

  session[:return_to] = request.path_info

  if session[:user]
    if validate_id_params(@all_city_ids, @city_id)
      @all_match_ids = @storage.all_match_id
      if validate_id_params(@all_match_ids, @match_id)
        @locations = @storage.find_match_location(@match_id)
        erb :view_location
      else
        status 404
        session[:error] = 'Invalid match ID'
        redirect "/cities/#{@city_id}"
      end
    else
      status 404
      session[:error] = 'Invalid city ID'
      redirect '/cities'
    end
  else
    redirect '/cities'
  end
end

# Edit given match location data
get '/cities/:id/match_locations/:match_id/edit' do
  @city_id = params[:id]
  @match_id = params[:match_id]
  @all_city_ids = @storage.all_city_id
  session[:return_to] = request.path_info

  if session[:user]
    if validate_id_params(@all_city_ids, @city_id)
      @all_match_ids = @storage.all_match_id
      if validate_id_params(@all_match_ids, @match_id)
        # @city = @storage.find_city(@city_id)
        @locations = @storage.find_match_location(@match_id)
        erb :edit_location
      else
        status 404
        session[:error] = 'Invalid match ID'
        redirect "/cities/#{@city_id}"
      end
    else
      status 404
      session[:error] = 'Invalid city ID'
      redirect '/cities'
    end
  else
    redirect '/login'
  end
end

post '/cities/:id/match_locations/:match_id/edit' do
  location_name = cap_format(params[:location_name])
  address = cap_format(params[:address])
  custom_matchbook = params[:custom_matchbook].downcase
  neighborhood = cap_format(params[:neighborhood])

  error = validate_match_location(location_name, address, custom_matchbook, neighborhood)
  if error
    session[:error] = error
    erb :edit_location
  else
    id = params[:id]
    match_id = params[:match_id]

    @storage.update_match_location(location_name, address, custom_matchbook, neighborhood, match_id)
    redirect "/cities/#{id}"
  end
end

post '/cities/:id/match_locations/:match_id/delete' do
  id = params[:id]
  match_id = params[:match_id]
  session[:success] = "#{@storage.find_match_location(match_id)[:location_name]} has been deleted"
  @storage.delete_match_location(id, match_id)

  redirect "/cities/#{id}"
end
