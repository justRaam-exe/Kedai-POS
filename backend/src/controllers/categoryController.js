const db = require('../models/dbModel');

exports.getCategories = (req, res) => {
    db.all("SELECT * FROM categories ORDER BY id ASC", [], (err, rows) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, data: rows });
    });
};

exports.createCategory = (req, res) => {
    const { name } = req.body;
    if (!name || !name.trim()) {
        return res.status(400).json({ success: false, message: 'Category name required!' });
    }

    const cleanName = name.trim();
    db.run(`INSERT INTO categories (name) VALUES (?)`, [cleanName], function (err) {
        if (err) {
            if (err,message.includes('UNIQUE')) {
                return res.status(400).json({ success: false, message: 'Category is already exists!' });
            }
            return res.status(500).json({ success: false, message: err.message });
        }

        res.json({
            success: true,
            message: 'Category created successfully!',
            data: { id: this.lastID, name: cleanName }
        });
    });
};