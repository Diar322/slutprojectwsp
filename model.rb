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

def insert_product(title, desc, price, file_path)
    db = connect_to_db()
    db.execute("INSERT INTO products (name, description, price, file_path) VALUES (?, ?, ?, ?)", title, desc, price, file_path)
end

def delete_product(id)
    db = connect_to_db()
    db.execute("DELETE FROM products WHERE id = ?", id)
end