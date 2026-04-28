const express = require('express');
const { check } = require('express-validator');
const authController = require('../controllers/authController');
const { verifyToken } = require('../middlewares/authMiddleware');
const { authorizeRoles } = require('../middlewares/roleMiddleware');

const router = express.Router();

const registerValidation = [
    check('name', 'Nama wajib diisi').not().isEmpty(),
    check('email', 'Email tidak valid').isEmail(),
    check('password', 'Password minimal 6 karakter').isLength({ min: 6 }),
    check('role', 'Role tidak valid').optional().isIn(['admin', 'requester', 'supervisor', 'finance', 'purchasing'])
];

router.post('/register', registerValidation, authController.register);
router.post('/login', authController.login);
router.get('/profile', verifyToken, authController.getProfile);
router.get('/users', verifyToken, authorizeRoles('admin'), authController.getAllUsers);

module.exports = router;
