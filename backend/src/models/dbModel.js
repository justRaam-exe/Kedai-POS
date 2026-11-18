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

// db.serialize(() => {
//     db.run(`CREATE TABLE IF NOT EXISTS users (
//         id INTERGER PRIMARY KEY AUTOINCREMENT,
//         username TEXT UNIQUE,
//         pin_code TEXT, -- contains 4 digit pin code
//         role TEXT -- 'Kasir' or 'owner'
//     )`);

//     db.get("SELECT COUNT(*) as count FROM users", (err, row) => {
//         if (row.count === 0) {
//             db.run(`INSERT INTO users (username, pin_code) VALUES ('KSR', '1357', 'kasir')`);
//             db.run(`INSERT INTO users (username, pin_code) VALUES ('OWN', '7531', 'owner')`);
//             console.log('Default users inserted into the database');
//         }
//     });
// });

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
});

module.exports = db;