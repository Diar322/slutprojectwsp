require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions


get('/')  do
  slim(:start)
end 

get('/browse') do
  @result = fetch_products()
  slim(:"products/index")
end

get('/browse/new') do
  if session[:id] == nil
    redirect('/login')
  end
  slim(:"products/new")
end

get('/browse/:id') do
  id = params[:id].to_i
  @result = fetch_product(id)
  slim(:"products/show") 
end


post('/browse/new') do
  title = params[:title]
  desc = params[:description]
  price = params[:price].to_i
  if params[:file] != nil
    file_path = params[:file][:filename]
    path = File.join("public/sheet_music/",file_path)
    File.write(path, File.read(params[:file][:tempfile]))  
  end

  insert_product(title, desc, price, file_path)

  
  redirect('/browse')
end

post('/browse/:id/delete') do
  id = params[:id].to_i
  delete_product(id)
  redirect('/browse')
end


get('/browse/:id/edit') do
  id = params[:id]
  db = SQLite3::Database.new('db/databas.db')
  db.results_as_hash = true
  @result = db.execute("SELECT * FROM products WHERE id = ?", id).first
  p @result
  #if @result["user_id"] == session[:id]
    # rätt personen är inloggad
  slim(:"products/edit")
  #else
    # fel person är inloggad
    #"Logga in först"
  #end
end

post('/browse/:id/update') do
  name = params[:name]
  desc = params[:description]
  price = params[:price]
  id = params[:id]
  db = SQLite3::Database.new('db/databas.db')
  db.execute("UPDATE products SET name=?,description=?,price=? WHERE id=?", name, desc, price, id)

  redirect('/browse')
end

post('/browse/:id/add') do

  db = SQLite3::Database.new('db/databas.db')
  db.execute("INSERT INTO user_product_rel (user_id, product_id) VALUES (?, ?)", )
  redirect('/browse')
end

  

get('/register') do
    slim(:register)
end

post('/registration_result') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/databas.db')
      db.execute("INSERT INTO users (username, pwdigest, role) VALUES (?,?,?)", username, password_digest, 0)
      redirect('/')
    else
      #fel
      "Lösenorden matchade inte!"
    end
end

post('/login_result') do
    username = params[:user]
    password = params[:pwd]
    db = SQLite3::Database.new('db/databas.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username=?", username).first
    #result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/')
    else
      "FEL LÖSEN"
    end
    redirect('/')
end

get('/login') do
    #login som gör cooldown för A nivå
    slim(:login)
end

get('/logout') do
  session.clear()
  redirect('/')
end