// Imports
// const express = require('express');

import express from 'express';
const router = express.Router();
import AuthService from '../services/auth_service';
import Middleware from '../middleware';
// const AuthService = require('../services/auth_service.js');
// const Middleware = require('../middleware.js');

router.post('/logout', AuthService.logout);
router.post('/login', AuthService.login);
router.put('/register', AuthService.register);
router.get('/status', AuthService.status);
router.post('/refreshToken', AuthService.refreshToken);
router.post(
  '/2fa/enable', // Must be before /2fa/verify
  Middleware.authUser,
  Middleware.csrfValidation,
  AuthService.enable2FA
);
router.post(
  '/2fa/verify', // Must be after /2fa/enable
  Middleware.authUser,
  Middleware.csrfValidation,
  AuthService.verify2FA
);
router.post(
  '/2fa/disable',
  Middleware.authUser,
  Middleware.csrfValidation,
  AuthService.disable2FA
);
export default router;
