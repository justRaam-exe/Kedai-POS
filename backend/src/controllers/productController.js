const db = require('../models/dbModel');

// Get all products
exports.getProducts = (req, res) => {
    db.all("SELECT * FROM products", [], (err, rows) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, data: rows });
    });
};

// add a new product
exports.addProduct = (req, res) => {
    const { name, price, stock, unit } = req.body;
    const query = `INSERT INTO products (name, price, stock, unit) VALUES (?, ?, ?, ?)`;
    db.run(query, [name, price, stock, unit], function(err) {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, message: 'Product added successfully', id: this.lastID });
    });
};

// Increase and decrease product stok and edit product
exports.updateProduct = (req, res) => {
    const { id } = req.params;
    const { name, price, stock, unit } = req.body;
    const query = `UPDATE products SET name = ?, price = ?, stock = ?, unit = ? WHERE id = ?`;
    db.run(query, [name, price, stock, unit, id], (err) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, message: 'Product updated successfully' });
    });
};

// Delete a product
exports.deleteProduct = (req, res) => {
    const { id } = req.params;
    db.run(`DELETE FROM products WHERE id = ?`, [id], (err) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, message: 'Product deleted successfully' });
    });
};