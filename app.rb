require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

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

get('/browse/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM product WHERE id = ?",id).first
    slim(:"browse/show")
end

get('/login') do
    slim(:login)
end

post('login_result') do
    session[:user] = params[:user]
    session[:pwd] = params[:pwd] 

    redirect('/')
end