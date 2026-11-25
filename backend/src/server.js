const express = require('express');
const cors = require('cors');
const db = require('./models/dbModel');
const authController = require('./controllers/authController');
const productController = require('./controllers/productController');
const salesController = require('./controllers/salesController');
const categoryController = require('./controllers/categoryController');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'API is running' });
});

app.post('/api/auth/login', authController.login);
app.get('/api/products', productController.getProducts);
app.post('/api/products', productController.addProduct);
app.put('/api/products/:id', productController.updateProduct);
app.delete('/api/products/:id', productController.deleteProduct);
app.post('/api/sales/transaction', salesController.createTransaction);
app.get('/api/categories', categoryController.getCategories);
app.post('/api/categories', categoryController.createCatagory);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
