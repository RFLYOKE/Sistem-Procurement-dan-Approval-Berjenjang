const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const userModel = require('../models/userModel');
const { successResponse, errorResponse } = require('../utils/response');

const register = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return errorResponse(res, errors.array()[0].msg, 400);
        }

        const { name, email, password, role, department } = req.body;

        const existingUser = await userModel.findUserByEmail(email);
        if (existingUser) {
            return errorResponse(res, 'Email sudah terdaftar.', 400);
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUserId = await userModel.createUser({
            name,
            email,
            password: hashedPassword,
            role,
            department
        });

        const newUser = await userModel.findUserById(newUserId);

        return successResponse(res, 'Registrasi berhasil', newUser, 201);
    } catch (error) {
        console.error('Register error:', error);
        return errorResponse(res, 'Terjadi kesalahan pada server', 500);
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return errorResponse(res, 'Email dan password wajib diisi', 400);
        }

        const user = await userModel.findUserByEmail(email);
        if (!user) {
            return errorResponse(res, 'Email atau password salah', 401);
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return errorResponse(res, 'Email atau password salah', 401);
        }

        if (!user.is_active) {
            return errorResponse(res, 'Akun Anda tidak aktif', 403);
        }

        const payload = {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            department: user.department
        };

        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN || '1d'
        });

        // Hapus password dari response
        delete user.password;

        return successResponse(res, 'Login berhasil', { token, user });
    } catch (error) {
        console.error('Login error:', error);
        return errorResponse(res, 'Terjadi kesalahan pada server', 500);
    }
};

const getProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await userModel.findUserById(userId);

        if (!user) {
            return errorResponse(res, 'User tidak ditemukan', 404);
        }

        return successResponse(res, 'Profil berhasil diambil', user);
    } catch (error) {
        console.error('Get profile error:', error);
        return errorResponse(res, 'Terjadi kesalahan pada server', 500);
    }
};

const getAllUsers = async (req, res) => {
    try {
        const users = await userModel.getAllUsers();
        return successResponse(res, 'Daftar user berhasil diambil', users);
    } catch (error) {
        console.error('Get all users error:', error);
        return errorResponse(res, 'Terjadi kesalahan pada server', 500);
    }
};

module.exports = {
    register,
    login,
    getProfile,
    getAllUsers
};
