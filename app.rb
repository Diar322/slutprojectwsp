require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

get('/')  do
    slim(:start)
end 