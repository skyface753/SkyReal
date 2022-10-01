// Imports
import express from 'express';
import Middleware from '../middleware';
import UserService from '../services/user_service';
const router = express.Router();
router.get('/username/isFree', UserService.checkIfUsernameIsFree);
router.put(
  '/username/update',
  Middleware.authUser,
  Middleware.csrfValidation,
  UserService.changeUsername
);
router.get(
  '/settings',
  Middleware.authUser,
  Middleware.csrfValidation,
  UserService.getSettings
);
export default router;
