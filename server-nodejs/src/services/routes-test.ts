import sendResponse from '../helpers/sendResponse';
import { Response } from 'express';
import { IUserFromCookieInRequest } from '../types/express-custom.d';

const RoutesTestService = {
  anonymous: async (req: IUserFromCookieInRequest, res: Response) => {
    sendResponse.success(res, {
      message: 'Anonymous',
      user: req.user,
    });
  },
  userIfCookie: async (req: IUserFromCookieInRequest, res: Response) => {
    sendResponse.success(res, {
      message: 'User if Cookie',
      user: req.user ? req.user : 'No user',
    });
  },
  user: async (req: IUserFromCookieInRequest, res: Response) => {
    sendResponse.success(res, {
      message: 'User',
      user: req.user,
    });
  },
  admin: async (req: IUserFromCookieInRequest, res: Response) => {
    sendResponse.success(res, {
      message: 'Admin',
      user: req.user,
    });
  },
};
export default RoutesTestService;
