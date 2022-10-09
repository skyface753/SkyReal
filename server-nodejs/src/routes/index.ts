// Imports
import express from 'express';
import auth from './auth';
import docs from './docs';
import test from './test';
import user from './user';
import reals from './reals';
import friends from './friends';
import search from './search';
import Middleware from '../middleware';
const router = express.Router();

// Routes
router.use('/auth', auth);
router.use('/docs', docs);
router.use('/test', test);
router.use('/user', user);
router.use('/reals', reals);
router.use('/friends', friends);
router.use('/search', search);

// Files uploads/reals
router.use(
  '/uploads/reals',
  Middleware.authUser,
  express.static('uploads/reals')
);
export default router;
