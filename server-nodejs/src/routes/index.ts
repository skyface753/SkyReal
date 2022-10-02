// Imports
import express from 'express';
import auth from './auth';
import docs from './docs';
import test from './test';
import user from './user';
import reals from './reals';
const router = express.Router();

// Routes
router.use('/auth', auth);
router.use('/docs', docs);
router.use('/test', test);
router.use('/user', user);
router.use('/reals', reals);

export default router;
