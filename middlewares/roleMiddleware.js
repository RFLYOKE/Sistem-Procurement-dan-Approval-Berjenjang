const { errorResponse } = require('../utils/response');

const authorizeRoles = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return errorResponse(res, 'Akses ditolak. Anda tidak memiliki izin untuk resource ini.', 403);
        }
        next();
    };
};

module.exports = { authorizeRoles };
