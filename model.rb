require 'bcrypt'
require 'sinatra/flash'

module Model
    $attempts = {}

    # Connects to db
    #
    # @return [SQLite3::Database] containing everything as hashes
    def connect_to_db()
        db = SQLite3::Database.new("db/databas.db")
        db.results_as_hash = true
        return db
    end

    # Fetches all products
    #
    # @return [Array] containing all products and their data as hashes
    def fetch_products()
        db = connect_to_db()
        return db.execute("SELECT * FROM products")
    end

    # Fetch specific product
    #
    # @param [Integer] id, the ID of the product
    # @return [Hash] containing the product
    def fetch_product(id)
        db = connect_to_db()
        return db.execute("SELECT * FROM products WHERE id = ?", id).first
    end

    # Fetch purchased products for user
    #
    # @param [Integer] user_id, the ID of the product
    # @return [Array] containing the purchased products as hashes
    def fetch_purchased_products(user_id)
        db = connect_to_db()
        return db.execute("SELECT * FROM products INNER JOIN user_product_rel ON products.id = user_product_rel.product_id WHERE user_id = ?", user_id)
    end

    # Attempts to add new row to products table
    #
    # @param [String] title, the title of the product
    # @param [String] desc, the desc of the product
    # @param [String] price, the price of the product
    # @param [String] filepath, the file_path of the product
    # @param [String] user_id, the user_id of the product user who created the product
    # @return [flash] success message
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


    # Attempts to delete a row from the articles table
    #
    # @param [Integer] article_id The article's ID
    # @param [Hash] params form data
    # @option params [String] title The title of the article
    # @option params [String] content The content of the article
    #
    # @return [Hash]
    #   * :error [Boolean] whether an error occured
    #   * :message [String] the error message
    def delete_product(id)
        db = connect_to_db()
        db.execute("DELETE FROM products WHERE id = ?", id)
        db.execute("DELETE FROM user_product_rel WHERE product_id = ?", id)
        flash[:notice] = "produkt raderad"
    end

    # Attempts to update a row in the products table
    #
    # @param [Integer] id The product's ID
    # @param [Integer] price, The price of the product
    # @option params [String] name, The title of the product
    # @option params [String] desc, The content of the product
    #
    # @return [flash] Success message
    def edit_product(name, desc, price, id)
        db = connect_to_db()
        db.execute("UPDATE products SET name=?,description=?,price=? WHERE id=?", name, desc, price, id)
        flash[:notice] = "produkt redigerad"
    end

    # Attempts to add new row to users table
    #
    # @param [String] username, the username of the user
    # @param [String] password, the password of the user
    # @param [String] password_confirm, the password_confirmed of the user
    # @return [flash] if error
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

    # Attempts to login
    #
    # @option params [String] username, The username
    # @option params [String] password, The password
    #
    # @return [true] if credentials match a user
    # @return [false] if credentials do not match a user
    def login(username, password)
        ip = request.ip

        if $attempts[ip] == nil
            #fine
        elsif (Time.now - $attempts[ip]).to_i < 10
            flash[:notice] = "Loggar in för snabbt!"
            return false
        end

        if password == nil || username == nil
            flash[:notice] = "Inga tomma värden!"
            return false
        end
        result = fetch_user(username)

        if result == nil
            flash[:notice] = "Inget konto med det användarnamnet!"
            return false
        end

        pwdigest = result["pwdigest"]
        if BCrypt::Password.new(pwdigest) == password
            flash[:notice] = "Loggade in!"
            return true
        else
            $attempts[ip] = Time.now
            flash[:notice] = "Fel lösenord!"
            return false
        end
    end

    # Searches for user with username
    #
    # @param [String] username
    #
    # @return [Hash] returns the user
    def fetch_user(username)
        db = connect_to_db()
        return db.execute("SELECT * FROM users WHERE username=?", username).first
    end

    # Searches for user with id
    #
    # @param [Integer] id
    #
    # @return [Hash] returns the user
    def fetch_user_id(id)
        db = connect_to_db()
        return db.execute("SELECT * FROM users WHERE id = ?", id).first
    end

    # Searches for user with id
    #
    # @return [Array] returns all users as hashes
    def fetch_users()
        db = connect_to_db()
        return db.execute("SELECT * FROM users")
    end

    # Adds a purchase
    #
    # @param [Integer] user_id, the users id
    # @param [Integer] product_id, the products id
    #
    # @return [flash] message confirming purchase
    def insert_purchase(user_id, product_id)
        db = connect_to_db()
        db.execute("INSERT INTO user_product_rel (user_id, product_id) VALUES (?, ?)", user_id,  product_id)
        flash[:notice] = "produkt köpt"
    end

    # Deletes a pruchase
    #
    # @param [Integer] id, the purchase id
    #
    # @return [flash] message confirming deletion
    def remove_purchase(id)
        db = connect_to_db()
        db.execute("DELETE FROM user_product_rel WHERE id = ?", id)
        flash[:notice] = "produkt borttagen från purchases"
    end

    # Deletes a user
    #
    # @param [Integer] id, the user id
    #
    # @return [flash] message confirming deletion
    def delete_user(id)
        db = connect_to_db()
        db.execute("DELETE FROM users WHERE id = ?", id)
        db.execute("DELETE FROM user_product_rel WHERE user_id = ?", id)
        flash[:notice] = "användare raderad"
    end

    # Edits a user
    #
    # @param [Integer] username, the new users username
    # @param [Integer] pwd, the new users password
    # @param [Integer] role, the new users role
    # @param [Integer] id, the users id
    #
    # @return [flash] message confirming deletion
    def edit_user(username, pwd, role, id)
        db = connect_to_db()
        pwddigest = BCrypt::Password.create(password)
        db.execute("UPDATE users SET username=?,pwdigest=?,role=? WHERE id=?", name, pwddigest, role, id)
        flash[:notice] = "användare redigerad"

    end

end
