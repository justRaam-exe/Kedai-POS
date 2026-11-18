const db = require('../models/dbModel');

exports.login = (req, res) => {
    const { username, pin_code } = req.body;

    if (!username || !pin_code) {
        return res.status(400).json({ success: false, message: 'Username and pin code are required' });
    }

    const query = `SELECT * FROM users WHERE username = ? AND pin_code = ?`;
    db.get(query, [username, pin_code], (err, user) => {
        if (err) {
            return res.status(500).json({ success: false, message: 'Server has a Problem' });
        }
        if (!user) {
            return res.status(401).json({ success: false, message: 'Invalid Username or PIN' });
        }

        return res.json({
            success: true,
            message: 'Login successful',
            data: {
                id: user.id,
                username:user.username,
                role: user.role
            }
        });
    });
};