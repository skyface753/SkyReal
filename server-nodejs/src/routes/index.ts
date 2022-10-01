// Imports
import express from 'express';
import auth from './auth';
import avatar from './avatar';
import docs from './docs';
import test from './test';
import user from './user';
const router = express.Router();

// Routes
router.use('/auth', auth);
router.use('/avatar', avatar);
router.use('/docs', docs);
router.use('/test', test);
router.use('/user', user);

export default router;
