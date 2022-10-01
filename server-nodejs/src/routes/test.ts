// Imports
import express from 'express';
import Middleware from '../middleware';
const router = express.Router();

import RoutesTestService from '../services/routes-test'; // Test Routes Authenticated

router.post('/anonym', RoutesTestService.anonymous); // Test Routes Not Authenticated
router.post(
  '/user',
  Middleware.authUser,
  Middleware.csrfValidation,
  RoutesTestService.user
);
router.post(
  '/admin',
  Middleware.authAdmin,
  Middleware.csrfValidation,
  RoutesTestService.admin
);

export default router;
