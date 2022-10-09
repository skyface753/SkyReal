import { Response } from 'express';
import { IUserFromCookieInRequest } from '../types/express-custom';
import db from './db';
import sendResponse from '../helpers/sendResponse';

type User = {
  id: number;
  username: string;
  email: string;
  password: string;
  roleFk: number;
};

const SearchService = {
  user: async (req: IUserFromCookieInRequest, res: Response) => {
    const { query } = req.query;

    if (!query) {
      return sendResponse.missingParams(res);
    }
    if (!req.user) {
      return sendResponse.authError(res);
    }
    const result = await db.query(
      'SELECT id, username FROM user WHERE username LIKE ? AND id != ?',
      [`%${query}%`, req.user.id]
    );
    const resultWithFriendship = await Promise.all(
      result.map(async (user: User) => {
        const fromUserToSearchUser = await db.query(
          'SELECT * FROM friendship WHERE user = ? AND friend = ?',
          [req.user?.id, user.id]
        );
        const fromSearchUserToUser = await db.query(
          'SELECT * FROM friendship WHERE user = ? AND friend = ?',
          [user.id, req.user?.id]
        );
        if (
          fromUserToSearchUser &&
          fromUserToSearchUser.length &&
          fromSearchUserToUser &&
          fromSearchUserToUser.length
        ) {
          return { ...user, friendship: 'friends' };
        }
        if (fromUserToSearchUser && fromUserToSearchUser.length) {
          return { ...user, friendship: 'pendingOut' };
        }
        if (fromSearchUserToUser && fromSearchUserToUser.length) {
          return { ...user, friendship: 'pendingIn' };
        }
        return { ...user, friendship: 'none' };
      })
    );
    return sendResponse.success(res, resultWithFriendship);
  },
};

export default SearchService;
