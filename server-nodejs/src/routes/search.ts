import express from 'express';
const router = express.Router();
import SearchService from '../services/search';
import Middleware from '../middleware';

router.get('/user', Middleware.authUser, SearchService.user);

export default router;
