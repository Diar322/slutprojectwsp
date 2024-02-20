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
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true

    @result = db.execute("SELECT * FROM products")

    slim(:"browse/index")
end

get('/browse/new') do
    slim(:"browse/new")
end

get('/browse/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM products WHERE id = ?",id).first
    slim(:"browse/show")
end


post('/browse/new') do
    title = params[:title]
    desc = params[:description]
    price = params[:price].to_i
    file_path = params[:file][:filename]

  
    db = SQLite3::Database.new("db/databas.db")
    db.execute("INSERT INTO products (name, description, price, file_path) VALUES (?, ?, ?, ?)", title, desc, price, file_path)

    path = File.join("public/sheet_music/",file_path)
    File.write(path, File.read(params[:file][:tempfile]))
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

post('login_result') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/todos')
    else
      "FEL LÖSEN"
    end
    redirect('/')
end

get('/login') do
    #login som gör cooldown för A nivå
    slim(:login)
end



get('/download/:file_path') do
    file_path = "sheet_music/#{params[:file_path]}"

    p file_path
    
    if File.exist?(file_path)
      send_file file_path, filename: "#{params[:file_path]}", type: 'application/pdf'
    else
      status 404
      "File not found"
    end
end