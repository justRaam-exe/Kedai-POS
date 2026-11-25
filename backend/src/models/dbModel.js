const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, '../../kedai_rheya.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Failed to connect to the database:', err.message);
    } else {
        console.log('Connected to the SQLite database')
    }
});

db.serialize(() => {
    // Jalankan perintah pembuatan tabel
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        pin_code TEXT NOT NULL,
        role TEXT NOT NULL
    )`, (err) => {
        if (err) {
            console.error("Error membuat tabel users:", err.message);
            return;
        }

        // Cek apakah data user sudah ada
        db.get("SELECT COUNT(*) as count FROM users", (err, row) => {
            if (!err && row && row.count === 0) {
                db.run(`INSERT INTO users (username, pin_code, role) VALUES ('kasirRheya', '1234', 'kasir')`);
                db.run(`INSERT INTO users (username, pin_code, role) VALUES ('ownerRheya', '9999', 'owner')`);
                console.log('Data dummy user default berhasil dimasukkan.');
            }
        });
    });

    db.run(`CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
    )`, (err) => {
        if (err) {
            console.error("Error make categories table:", err.message);
        } else {
            console.log('Categories table created successfully');
        }
    }) 

    db.run(`CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        item_code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock REAL NOT NULL,
        unit TEXT NOT NULL,
        min_stock REAL NOT NULL DEFAULT 0,
        image_path TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
    )`, (err) => {
        if (err) {
            console.error("Error make Products table:", err.message);
        } else {
            console.log('Products table created successfully');
        }
    });

    db.run(`CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PROMARY KEY AUTOINCREMENT,
        invoice_code TEXT UNIQUE NOT NULL,
        payment_method TEXT NOT NULL, -- cash or qris
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL NOT NULL,
        created_at TEXT NOT NULL
    )`, (err) => {
        if (err) {
            console.error("Error creating transactions table:", err.message);
        } else {
            console.log('Transactions table created successfully');
        }
    });
    
    db.run(`CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        qty REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
    )`, (err) => {
        if (err) {
            console.error("Error creating transaction items table:", err.message);
        } else {
            console.log('Transaction items table created successfully');
        }
    });
});

module.exports = db;