import express from 'express';
const router = express.Router();
import FriendsService from '../services/friends';
import Middleware from '../middleware';

router.post('/add', Middleware.authUser, FriendsService.add);
router.post('/remove', Middleware.authUser, FriendsService.remove);
router.get(
  '/requests',
  Middleware.authUser,
  FriendsService.getIncomingFriendRequests
);
router.get('/all', Middleware.authUser, FriendsService.getAll);
export default router;
