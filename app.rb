require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative 'model.rb'

enable :sessions

include Model

# Displays landing page
#
get('/')  do
  slim(:start)
end

# Displays all products
#
#@see Model#fetch_products
get('/browse/') do
  @result = fetch_products()
  slim(:"products/index")
end

# Display product creation page
#
get('/protected/browse/new') do
  if session[:user_id] == nil
    redirect('/login')
  end
  slim(:"products/new")
end

# Displays a single Product
#
# @param [Integer] :id, the ID of the product
# @see Model#fetch_product
get('/browse/:id') do
  id = params[:id].to_i
  @result = fetch_product(id)
  slim(:"products/show")
end

# Creates a new product and redirects to '/browse/'
#
# @param [String] title, The title of the product
# @param [String] desc, The description of the product
# @param [String] price, The price of the product
# @param [String] price, The file_path of the product
#
# @see Model#insert_product
post('/browse') do
  title = params[:title]
  desc = params[:description]
  price = params[:price].to_i
  if params[:file] != nil
    file_path = params[:file][:filename]
    path = File.join("public/sheet_music/",file_path)
    File.write(path, File.read(params[:file][:tempfile]))
  end

  insert_product(title, desc, price, file_path, session["user_id"])
  redirect('/browse/')
end

# Creates a new purchase and redirects to '/browse/'
#
# @param [Integer] :id, the ID of the product
#
# @see Model#insert_purchase
post('/protected/browse/:id/add') do
  id = params[:id]
  insert_purchase(session[:user_id], id.to_i)
  redirect('/browse/')
end

# Removes a purchase and redirects to '/browse/'
#
# @param [Integer] :id, the ID of the product
#
# @see Model#remove_purchase
post('/protected/browse/:id/remove') do
  id = params[:id]
  remove_purchase(id)
  redirect('/browse/')
end

# Deletes a product and redirects to '/browse/'
#
# @param [Integer] :id, the ID of the product
#
# @see Model#delete_product
post('/private/browse/:id/delete') do
  id = params[:id].to_i
  delete_product(id)
  redirect('/browse/')
end

# Displays the edit menu for a product
#
# @param [Integer] :id, the ID of the product
# @see Model#fetch_product
get('/private/browse/:id/edit') do
  id = params[:id].to_i
  @result = fetch_product(id)
  slim(:"products/edit")
end

# Updates an existing product and redirects to '/browse/'
#
# @param [String] name, The new title of the product
# @param [String] desc, The new description of the product
# @param [String] price, The new price of the product
# @param [Integer] :id, The id of the product
#
# @see Model#edit_product
post('/private/browse/:id/update') do
  name = params[:name]
  desc = params[:description]
  price = params[:price]
  id = params[:id]

  edit_product(name, desc, price, id)
  redirect('/browse/')
end

# Displays the user registration page
#
get('/register') do
    slim(:"users/register")
end

# Attempts registration
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] password_confirm, The repeated password
#
# @see Model#register_user
post('/registration_result') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if register_user(username, password, password_confirm)
      redirect('/')
    else
      return register_user(username, password, password_confirm)
    end
end

# Attempts login and updates the session
#
# @param [String] username, The username
# @param [String] password, The password
#
# @see Model#login
post('/login_result') do
    username = params[:user]
    password = params[:pwd]

    if login(username, password)
      result = fetch_user(username)
      session[:user_id] = result["id"]
      session[:role] = result["role"]
      redirect('/')
    else
      redirect('/login')
    end

end

# Displays the login page
#
get('/login') do
    slim(:"users/login")
end

# Logs the user out, clears session, and redirects to '/'
#
get('/logout') do
  session.clear()
  redirect('/')
end

# Displays purchases
#
# @param [Integer] :user_id, The id of the user
# @see Modepurchasel#fetch_purchased_products
get('/protected/purchases') do
  @result = fetch_purchased_products(session[:user_id])
  p fetch_purchased_products(session[:user_id])
  slim(:purchases)
end

before('/protected/*') do
  if session[:user_id] == nil
    redirect('/')
  end
end

before('/private/browse/:id/*') do
  id = params[:id].to_i
  product = fetch_product(id)
  if session[:user_id] != product["created_by"] && session[:role] != 1
    redirect('/')
  end
end

before('/admin/*') do
  if session[:role] != 1
    redirect('/')
  end
end

# Display list of users
#
get('/admin/users/') do
  @result = fetch_users()
  slim(:"users/index")
end

# Displays the edit menu for a user
#
# @param [Integer] :id, The id of the product
# @see Model#fetch_user_id
get('/admin/users/:id/edit') do
  id = params[:id].to_i
  @result = fetch_user_id(id)
  slim(:"users/edit")
end

# Updates an existing user and redirects to '/admin/users/'
#
# @param [String] name, The new username of the user
# @param [String] pwd, The new password of the user
# @param [String] role, The new role of the user
# @param [Integer] :id, The id of the user
#
# @see Model#edit_user
post('/admin/users/:id/update') do
  name = params[:name]
  pwd = params[:pwd]
  role = params[:role]
  id = params[:id]

  edit_user(name, pwd, role, id)
  redirect('/admin/users/')
end

# Deletes an existing user
#
# @param [Integer] :id, The id of the user
#
# @see Model#delete_user
post('/admin/users/:id/delete') do
  id = params[:id].to_i
  delete_user(id)
  redirect('/admin/users/')
end
