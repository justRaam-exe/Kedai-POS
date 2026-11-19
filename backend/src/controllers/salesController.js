const db = require('../models/dbModel');

exports.createTransaction = (req, res) => {
    const { payment_method, paid_amount, items } = req.body;

    if (!payment_method || !['cash', 'qris'].includes(payment_method)) {
        return res.status(400).json({ success: false, message: 'Invalid Payment Method' });
    }

    if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ success: false, message: 'Item cart still empty!' });
    }

    const totalAmount = items.reduce((sum, item) => sum + (Number(item.price) * Number(item.qty)), 0);
    const finalPaid = payment_method === 'qris' ? totalAmount : Number(paid_amount || 0);

    if (payment_method === 'cash' && finalPaid < totalAmount) {
        return res.status(400).json({ success: false, message: 'Paid amount is less than total amount!'});
    }

    const changeAmount = payment_method === 'qris' ? 0 : finalPaid - totalAmount;
    const now = new Date();
    const createdAt = now.toISOString();
    const invoiceCode = `INV-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${Date.now().toString().slice(-5)}`;

    db.serialize(() => {
        db.run('BEGIN TRANSACTION');

        const insertTxQuery = `
            INSERT INTO transactions (invoice_code, payment_method, total_amount, paid_amount, change_amount, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        db.run(insertTxQuery, [invoiceCode, payment_method, totalAmount, finalPaid, changeAmount, createdAt], function (err) {
            if (err) {
                db.run('ROLLBACK');
                return res.status(500).json({ success: false, message: 'Failed to save transaction: ' + err.message });
            }

            const transactionId = this.lastID;
            const insertItemStmt = db.prepare(`
                INSERT INTO transaction_items (transaction_id, product_id, product_name, qty, subtotal)
                VALUES (?, ?, ?, ?, ?)`
            );
            const updateStockStmt = db.prepare(`
                UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?
            `);

            let hasError = false;

            for (const item of items) {
                const subtotal = Number(item.price) * Number(item.gty);
                insertItemStmt.run(
                    [transactionId, item.product_id, item.product_name, Number(item.price), Number(item.qty), subtotal],
                    (itemErr) => {
                        if (itemErr && !hasError) {
                            hasError = true;
                            db.run('ROLLBACK');
                            return res.status(500).json({ success: false, message: 'Failed to save item detail: ' + itemErr.message });
                        }
                    }
                );

                updateStockStmt.run([Number(item.qty), item.product_id], (stockErr) => {
                    if (stockErr && !hasError) {
                        hasError = true;
                        db.run('ROLLBACK');
                        return res.status(500).json({ success: false, message: 'Failed to update stock: ' + stockErr.message });
                    }
                });
            }

            insertItemStmt.finalize();
            updateStockStmt.finalize((finErr) => {
                if (hasError) return;
                if (finErr) {
                    db.run('ROLLBACK');
                    return res.status(500).json({ success: false, message: 'Failed to finalized stokc: ' + finErr.message });
                }

                db.run('COMMIT', (commitErr) => {
                    if (commitErr) {
                        return res.status(500).json({ success: false, message: 'Failed to commit transaction: ' + commitErr.message });
                    }

                    return res.json({ 
                        success: true,
                        message: 'Transaction created successfully',
                        data: {
                            id: transactionId,
                            invoice_code: invoiceCode,
                            payment_method,
                            total_amount: totalAmount,
                            paid_amount: finalPaid,
                            change_amount: changeAmount,
                            created_at: createdAt,
                        },
                    });
                });
            });
        });
    });
};