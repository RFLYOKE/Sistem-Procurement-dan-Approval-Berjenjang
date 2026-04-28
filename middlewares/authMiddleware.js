const jwt = require('jsonwebtoken');
const { errorResponse } = require('../utils/response');

const verifyToken = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return errorResponse(res, 'Akses ditolak. Token tidak ditemukan.', 401);
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded; // { id, name, email, role, department }
        next();
    } catch (error) {
        return errorResponse(res, 'Token tidak valid atau sudah kadaluarsa.', 401);
    }
};

module.exports = { verifyToken };
