require 'bcrypt'
require 'sinatra/flash'

def connect_to_db()
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    return db
end

def fetch_products()
    db = connect_to_db()
    return db.execute("SELECT * FROM products")
end

def fetch_product(id)
    db = connect_to_db()
    return db.execute("SELECT * FROM products WHERE id = ?", id).first
end

def fetch_purchased_products(user_id)
    db = connect_to_db()
    return db.execute("SELECT * FROM products INNER JOIN user_product_rel ON products.id = user_product_rel.product_id WHERE user_id = ?", user_id)
end

def insert_product(title, desc, price, file_path, user_id)
    db = connect_to_db()
    if title == nil || desc == nil|| price == nil || file_path == nil
        flash[:notice] = "rutorna kan ej vara tomma"
    elsif !(price.integer?)
        flash[:notice] = "priset måste vara en tal"
    elsif price.to_i > 9999
        flash[:notice] = "priset kan ej vara över 9999"
    else
        db.execute("INSERT INTO products (name, description, price, file_path, created_by) VALUES (?, ?, ?, ?, ?)", title, desc, price, file_path, user_id)
        redirect('/browse/')
        flash[:notice] = "produkt adderad"
    end
    redirect('/browse/new')
end

def delete_product(id)
    db = connect_to_db()
    db.execute("DELETE FROM products WHERE id = ?", id)
    flash[:notice] = "produkt raderad"
end

def edit_product(name, desc, price, id)
    db = connect_to_db()
    db.execute("UPDATE products SET name=?,description=?,price=? WHERE id=?", name, desc, price, id)
    flash[:notice] = "produkt redigerad"
end

def register_user(username, password, password_confirm)
    db = connect_to_db()

    if password != password_confirm
        flash[:notice] = "inte samma lösenord"
    elsif password.length > 8
        flash[:notice] = "lösenord måste vara längre än 8!"
    elsif password != /[A-Z]/
        flash[:notice] = "LÖSENORD MÅSTE HA EN STOR BOKSTAV"
    elsif password != /[0-9]/
        flash[:notice] = "L0S3N 03D MÅ573 H2 3N 519931"
    elsif fetch_user(username) != nil
        flash[:notice] = "användarnmanet används redan"
    else
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username, pwdigest, role) VALUES (?,?,?)", username, password_digest, 0)
        redirect('/')
    end
    redirect('/register')
end

def fetch_user(username)
    db = connect_to_db()
    return db.execute("SELECT * FROM users WHERE username=?", username).first
end

def insert_purchase(user_id, product_id)
    db = connect_to_db()
    db.execute("INSERT INTO user_product_rel (user_id, product_id) VALUES (?, ?)", user_id,  product_id)
    flash[:notice] = "produkt köpt"
end

def remove_purchase(id)
    db = connect_to_db()
    db.execute("DELETE FROM user_product_rel WHERE id = ?", id)
    flash[:notice] = "produkt borttagen från purchases"
end

# def is_purchased(user_id, product_id)
#     db = connect_to_db()
#     products = db.execute("SELECT * FROM user_product_rel WHERE user_id = ?", user_id)
#     products.each do |product|
#         if product['id'] == product_id
#             return true
#         end
#     end
#     return false
# end
