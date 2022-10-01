import { Request } from 'express';

export interface IUserFromCookieInRequest extends Request {
  user?: {
    id: number;
    username: string;
    email: string;
    password: string;
    roleFk: number;
  };
}
