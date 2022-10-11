import { Response } from 'express';
import { IUserFromCookieInRequest } from '../types/express-custom';
import db from './db';
import sendResponse from '../helpers/sendResponse';

export enum FriendStatus {
  FRIENDS = 'friends',
  PENDINGOUT = 'pendingOut',
  PENDINGIN = 'pendingIn',
  NONE = 'none',
}

// type User = {
//   id: number;
//   username: string;
//   email: string;
//   password: string;
//   roleFk: number;
// };

export type UserResponse = {
  id: number;
  username: string;
  email: string;
  roleFk: number;
  friendship: FriendStatus;
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
    const UserResponse: UserResponse[] = [];
    for (const user of result) {
      const fromUserToSearchUser = await db.query(
        'SELECT * FROM friendship WHERE user = ? AND friend = ?',
        [req.user.id, user.id]
      );
      const fromSearchUserToUser = await db.query(
        'SELECT * FROM friendship WHERE user = ? AND friend = ?',
        [user.id, req.user.id]
      );
      if (
        fromUserToSearchUser &&
        fromUserToSearchUser.length &&
        fromSearchUserToUser &&
        fromSearchUserToUser.length
      ) {
        UserResponse.push({
          ...user,
          friendship: FriendStatus.FRIENDS,
        });
      } else if (fromUserToSearchUser && fromUserToSearchUser.length) {
        UserResponse.push({
          ...user,
          friendship: FriendStatus.PENDINGOUT,
        });
      } else if (fromSearchUserToUser && fromSearchUserToUser.length) {
        UserResponse.push({
          ...user,
          friendship: FriendStatus.PENDINGIN,
        });
      } else {
        UserResponse.push({
          ...user,
          friendship: FriendStatus.NONE,
        });
      }
    }
    return sendResponse.success(res, UserResponse);

    // const resultWithFriendship = await Promise.all(
    //   result.map(async (user: User) => {
    //     const fromUserToSearchUser = await db.query(
    //       'SELECT * FROM friendship WHERE user = ? AND friend = ?',
    //       [req.user?.id, user.id]
    //     );
    //     const fromSearchUserToUser = await db.query(
    //       'SELECT * FROM friendship WHERE user = ? AND friend = ?',
    //       [user.id, req.user?.id]
    //     );
    //     if (
    //       fromUserToSearchUser &&
    //       fromUserToSearchUser.length &&
    //       fromSearchUserToUser &&
    //       fromSearchUserToUser.length
    //     ) {
    //       return { ...user, friendship: 'friends' };
    //     }
    //     if (fromUserToSearchUser && fromUserToSearchUser.length) {
    //       return { ...user, friendship: 'pendingOut' };
    //     }
    //     if (fromSearchUserToUser && fromSearchUserToUser.length) {
    //       return { ...user, friendship: 'pendingIn' };
    //     }
    //     return { ...user, friendship: 'none' };
    //   })
    // );
    // return sendResponse.success(res, resultWithFriendship);
  },
};

export default SearchService;
