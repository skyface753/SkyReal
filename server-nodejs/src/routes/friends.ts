import express from 'express';
const router = express.Router();
import FriendsService from '../services/friends';
import Middleware from '../middleware';

router.post('/add', Middleware.authUser, FriendsService.add);
router.post('/remove', Middleware.authUser, FriendsService.remove);
export default router;
