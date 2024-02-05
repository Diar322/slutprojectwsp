require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative 'model.rb'

enable :sessions


get('/')  do
    slim(:start)
end 

get('/browse') do
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true

    @result = db.execute("SELECT * FROM product")

    slim(:"browse/index")
end

get('/browse/new') do
    slim(:"browse/new")
end

get('/browse/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM product WHERE id = ?",id).first
    slim(:"browse/show")
end


post('/browse/new') do
    title = params[:title]
    desc = params[:description]
    price = params[:price].to_i
    file_path = params[:file][:filename]

  
    db = SQLite3::Database.new("db/databas.db")
    db.execute("INSERT INTO product (name, description, price, file_path) VALUES (?, ?, ?, ?)", title, desc, price, file_path)

    path = File.join("public/sheet_music/",file_path)
    File.write(path, File.read(params[:file][:tempfile]))
    redirect('/browse')
end
  

get('/register') do
    slim(:register)
end

get('/login') do
    slim(:login)
end

post('login_result') do
    session[:user] = params[:user]
    session[:pwd] = params[:pwd] 

    redirect('/')
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