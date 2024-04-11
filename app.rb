require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative 'model.rb'

enable :sessions

get('/')  do
  slim(:start)
end

get('/browse/') do
  @result = fetch_products()
  slim(:"products/index")
end

get('/protected/browse/new') do
  if session[:user_id] == nil
    redirect('/login')
  end
  slim(:"products/new")
end

get('/browse/:id') do
  id = params[:id].to_i
  @result = fetch_product(id)
  slim(:"products/show")
end


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

post('/protected/browse/:id/add') do
  id = params[:id]
  insert_purchase(session[:user_id], id.to_i)
  redirect('/browse/')
end

post('/protected/browse/:id/remove') do
  id = params[:id]
  remove_purchase(id)
  redirect('/browse/')
end

post('/private/browse/:id/delete') do
  id = params[:id].to_i
  delete_product(id)
  redirect('/browse/')
end

get('/private/browse/:id/edit') do
  id = params[:id].to_i
  @result = fetch_product(id)
  slim(:"products/edit")
end

post('/private/browse/:id/update') do
  name = params[:name]
  desc = params[:description]
  price = params[:price]
  id = params[:id]

  edit_product(name, desc, price, id)
  redirect('/browse/')
end

get('/register') do
    slim(:register)
end

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

post('/login_result') do
    username = params[:user]
    password = params[:pwd]

    if password == nil || username == nil
      redirect('/login')
    end

    result = fetch_user(username)
    pwdigest = result["pwdigest"]
    if BCrypt::Password.new(pwdigest) == password
      session[:user_id] = result["id"]
      session[:role] = result["role"]
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
