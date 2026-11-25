const db = require('../models/dbModel');

// Get all products
function generateNextCode(callback) {
    db.get("SELECT COUNT(*) as total FROM products", [], (err, row) => {
        if (err) return callback(err);
        const nextNum = (row?.total || 0) + 1;
        const code = `KSR${String(nextNum).padStart(3, '0')}`;
        callback(null, code);
    });
}

// Get all products include category name
exports.getProducts = (req, res) => {
    const query = `
        SELECT p.*, c.name AS category_name
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        ORDER BY p.id DESC
    `;
    db.all(query, [], (err, rows) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, data: rows });
    });
};

// Add a new product
exports.addProduct = (req, res) => {
    const { name, price, stock, unit, category_id, min_stock, image_path } = req.body;

    if (!name || !name.trim()) {
        return res.status(400).json({ success: false, message: 'Product name is required!' });
    }

    const finalizeInsert = (resolvedCode) => {
        const query = `
            INSERT INTO products (category_id, item_code, name, price, stock, unit, min_stock, image_path)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        db.run(
            query,
            [
                category_id || null,
                resolvedCode,
                name.trim(),
                Number(price || 0),
                Number(stock || 0),
                unit || 'pcs',
                Number(min_stock || 0),
                image_path || null
            ],
            function (err) {
                if (err) {
                    return res.status(500).json({ success: false, message: err.message });
                }
                res.json({
                    success: true,
                    message: 'Product added successfully!',
                    data: { id: this.lastID, item_code: resolvedCode }
                });
            }
        );
    };

    if (item_code && item_code.trim()) {
        finalizeInsert(item_code.trim().toUpperCase());
    } else {
        generateNextCode((err, autoCode) => {
            if (err) return res.status(500).json({ success: false, message: err.message });
            finalizeInsert(autoCode);
        });
    }
};

// Update an existing product
exports.updateProduct = (req, res) => {
    const { id } = req.params;
    const { name, price, stock, unit, category_id, min_stock, item_code, image_path } = req.body;

    const query = `
        UPDATE products
        SET category_id = ?, item_code = ?, name = ?, price = ?, stock = ?, unit = ?, min_stock = ?, image_path = ?
        WHERE id = ?
    `;

    db.run(
        query,
        [
            category_id || null,
            (item_code || '').trim(),
            (name || '').trim(),
            Number(price || 0),
            Number(stock || 0),
            unit || 'pcs',
            Number(min_stock || 0),
            image_path || null,
            id,
        ],
        function (err) {
            if (err) return res.status(500).json({ success: false, message: err.message });
            if (this.changes === 0) {
                return res.status(404).json({ success: false, message: 'Product not found!' });
            }
            res.json({ success: true, message: 'Product updated successfully!' });
        }
    );
};

// Delete a product
exports.deleteProduct = (req, res) => {
    const { id } = req.params;
    db.run(`DELETE FROM products WHERE id = ?`, [id], function (err) {
        if (err) return res.status(500).json({ success: false, message: err.message });
        if (this.changes === 0) {
            return res.status(404).json({ success: false, message: 'Product not found!' });
        }
        res.json({ success: true, message: 'Product deleted successfully!' });
    });
};