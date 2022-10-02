import db from './db';
import config from '../config.json';
import bycrypt from 'bcrypt';
import sendResponse from '../helpers/sendResponse';
import speakeasy from 'speakeasy';
import {
  validateEmail,
  validatePassword,
  validateUsername,
} from '../helpers/validator';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import * as redis from 'redis';
import middleware from '../middleware';
import { Request, Response } from 'express';
import { IUserFromCookieInRequest } from '../types/express-custom';
import { IAccessTokenPayload } from '../types/jwt-payload';

const redisClient = redis.createClient({
  url: ('redis://' + config.REDIS.host + ':' + config.REDIS.port).toString(),
  //   legacyMode: true,
});

// const redisClient = redis.createClient({
// 	config.REDIS_HOST: string,
// 	port: config.REDIS_PORT,
// 	password: config.REDIS_PASSWORD,
// });

// const redisClient = redis.createClient({
// 	host: config.REDIS.host,
// 	port: config.REDIS.port,
// });

redisClient.on('error', (err) => {
  console.log('Error ' + err);
});

redisClient.on('connect', () => {
  console.log('Connected to Redis');
});

redisClient.connect();

// Prevent brute force attacks
const failures: { [key: string]: { count: number; nextTry: Date } } = {};
/**
 * Stores the login failure information in the session.
 * @param {string} remoteIp The remote IP address.
 */
function onLoginFail(remoteIp: string) {
  const f = (failures[remoteIp] = failures[remoteIp] || {
    count: 0,
    nextTry: new Date(),
  });
  ++f.count;
  if (f.count % 3 == 0) {
    f.nextTry.setTime(Date.now() + 1000 * 60 * 1); // 2 minutes
  }
}

/**
 * Remove the login failure information from the session.
 * @param {string} remoteIp The remote IP address.
 */
function onLoginSuccess(remoteIp: string) {
  delete failures[remoteIp];
}

// Clean up people that have given up
const MINS10 = 600000;
const MINS30 = 3 * MINS10;
setInterval(function () {
  for (const ip in failures) {
    if (Date.now() - failures[ip].nextTry.getTime() > MINS30) {
      delete failures[ip];
    }
  }
}, MINS30);

const AuthService = {
  logout: async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    res.clearCookie('jwt');
    if (!refreshToken) {
      return sendResponse.authError(res);
    }
    const tokenInRedis = await redisClient.get(refreshToken);
    if (!tokenInRedis) {
      return sendResponse.error(res);
    }
    await redisClient.del(refreshToken);
    sendResponse.success(res, 'Logged out');
  },
  login: async (req: Request, res: Response) => {
    const { email, password, totpCode } = req.body;
    if (!email || !password) {
      sendResponse.missingParams(res);
      return;
    }
    if (!validateEmail(email)) {
      sendResponse.error(res);
      return;
    }
    const remoteIp = req.ip;
    const f = failures[remoteIp];
    if (f && Date.now() < f.nextTry.getTime()) {
      sendResponse.error(res);
      return;
    }
    let user = await db.query(
      'SELECT * FROM user LEFT JOIN user_2fa ON user_2fa.userFk = user.id LEFT JOIN avatar ON avatar.userFk = user.id WHERE email = ?',
      [email.toLowerCase()]
    );
    if (user && user.length === 0) {
      onLoginFail(remoteIp);
      sendResponse.error(res);
      return;
    }
    user = user[0];

    const match = await bycrypt.compare(password, user.password);
    if (!match) {
      onLoginFail(remoteIp);
      sendResponse.error(res);
      return;
    }
    if (user.secretBase32 && user.verified) {
      if (!totpCode) {
        return res.status(400).send({
          success: false,
          message: '2FA required',
        });
      }
      const verified = speakeasy.totp.verify({
        secret: user.secretBase32,
        encoding: 'base32',
        token: totpCode,
      });
      if (!verified) {
        return sendResponse.error(res);
      }
    }

    onLoginSuccess(remoteIp);
    // user = {
    //   id: user.id,
    //   username: user.username,
    //   email: user.email,
    //   roleFk: user.roleFk,
    //   avatar: user.generatedPath,
    // };
    createAndSendTokens(res, user.id);
  },
  register: async (req: Request, res: Response) => {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      console.log('Missing : ', username, email, password);
      sendResponse.missingParams(res);
      return;
    }
    // Check if user already exists
    let user = await db.query(
      'SELECT * FROM user WHERE username = ? OR email = ?',
      [username, email]
    );

    if (user.length > 0) {
      sendResponse.error(res);
      return;
    }
    if (password.length < 8) {
      sendResponse.error(res);
      return;
    }
    if (!validateEmail(email)) {
      sendResponse.error(res);
      return;
    }
    if (!validatePassword(password)) {
      sendResponse.error(res);
      return;
    }
    if (!validateUsername(username)) {
      sendResponse.error(res);
      return;
    }
    // Hash password
    const hashedPassword = await bycrypt.hash(password, config.BCRYPT_ROUNDS);
    // Create user
    user = await db.query(
      'INSERT INTO user (username, email, password, roleFk) VALUES (?, ?, ?, 1)',
      [username, email, hashedPassword]
    );
    if (!user) {
      sendResponse.error(res);
      return;
    }
    // user = {
    //   id: user.insertId,
    //   username,
    //   email,
    //   roleFk: 1,
    //   avatar: null,
    // };

    createAndSendTokens(res, user.insertId);
  },
  // Before verifying
  enable2FA: async (req: IUserFromCookieInRequest, res: Response) => {
    const { password } = req.body;
    const requestingUser = req.user;
    const email = requestingUser?.email;
    if (!email || !password) {
      console.log('Missing : ', email, password);
      sendResponse.missingParams(res);
      return;
    }
    // Check if user already has 2FA
    let user = await db.query(
      'SELECT * FROM user LEFT JOIN user_2fa ON user_2fa.userFk = user.id WHERE email = ?',
      [email]
    );
    if (user.length === 0) {
      return sendResponse.error(res);
    }
    user = user[0];
    if (user.secretBase32 && user.verified) {
      return sendResponse.error(res);
    } else if (user.secretBase32 && !user.verified) {
      console.log('User has 2FA but not verified - deleting and re-creating');
      await db.query('DELETE FROM user_2fa WHERE userFk = ?', [user.id]);
    }

    // Verify password
    const match = await bycrypt.compare(password, user.password);
    if (!match) {
      return sendResponse.error(res);
    }
    const secret = speakeasy.generateSecret({
      otpauth_url: true,
      name: config.MFA_Issuer + ' (' + user.email + ')',
    });
    const url = secret.otpauth_url;
    const secretBase32 = secret.base32;
    const dbResult = await db.query(
      'INSERT INTO user_2fa (userFk, secretBase32) VALUES (?, ?)',
      [user.id, secretBase32]
    );
    if (!dbResult) {
      sendResponse.error(res);
      return;
    }
    sendResponse.success(res, {
      url,
      secretBase32,
    });
  },
  // After enabling
  verify2FA: async (req: IUserFromCookieInRequest, res: Response) => {
    const { currentCode } = req.body;
    const requestingUser = req.user;
    const email = requestingUser?.email;
    if (!email || !currentCode) {
      console.log('Missing : ', email, currentCode);
      return sendResponse.missingParams(res);
    }
    // Check if user already has 2FA
    let user = await db.query(
      'SELECT * FROM user LEFT JOIN user_2fa ON user_2fa.userFk = user.id WHERE email = ? ',
      [email]
    );
    if (user.length === 0) {
      return sendResponse.error(res);
    }
    user = user[0];
    if (!user.secretBase32) {
      return sendResponse.error(res);
    }
    if (user.verified) {
      return sendResponse.error(res);
    }
    const verified = speakeasy.totp.verify({
      secret: user.secretBase32,
      encoding: 'base32',
      token: currentCode,
    });
    if (!verified) {
      return sendResponse.error(res);
    }
    const dbResult = await db.query(
      'UPDATE user_2fa SET verified = 1 WHERE userFk = ?',
      [user.id]
    );
    if (!dbResult) {
      sendResponse.error(res);
      return;
    }
    sendResponse.success(res, {
      message: '2FA verified',
    });
  },
  disable2FA: async (req: IUserFromCookieInRequest, res: Response) => {
    const { password, totpCode } = req.body;
    const requestingUser = req.user;
    const email = requestingUser?.email;
    if (!email || !password || !totpCode) {
      console.log('Missing : ', email, password, totpCode);
      return sendResponse.missingParams(res);
    }
    // Check if user already has 2FA
    let user = await db.query(
      'SELECT * FROM user LEFT JOIN user_2fa ON user_2fa.userFk = user.id WHERE email = ? ',
      [email]
    );
    if (user.length === 0) {
      return sendResponse.error(res);
    }
    user = user[0];
    if (!user.secretBase32 || !user.verified) {
      return sendResponse.error(res);
    }
    // Verify password
    const match = await bycrypt.compare(password, user.password);
    if (!match) {
      return sendResponse.error(res);
    }
    // Verify 2FA
    const verified = speakeasy.totp.verify({
      secret: user.secretBase32,
      encoding: 'base32',
      token: totpCode,
    });
    if (!verified) {
      return sendResponse.error(res);
    }
    const dbResult = await db.query('DELETE FROM user_2fa WHERE userFk = ?', [
      user.id,
    ]);
    if (!dbResult) {
      return sendResponse.error(res);
    }
    sendResponse.success(res, {
      message: '2FA disabled',
    });
  },

  refreshToken: async (req: Request, res: Response) => {
    const refreshToken = req.body.refreshToken;
    if (!refreshToken) {
      sendResponse.missingParams(res);
      return;
    }
    const token = await redisClient.get(refreshToken);
    if (!token) {
      return sendResponse.error(res);
    }
    const userFromRedis = JSON.parse(token);
    const user = await db.query('SELECT * FROM user WHERE id = ?', [
      userFromRedis.id,
    ]);
    if (user.length === 0) {
      return sendResponse.error(res);
    }
    delete user[0].password;
    createAndSendTokens(res, user[0].id);
    // Delete refresh token
    await redisClient.del(refreshToken);
  },
  status: async (req: Request, res: Response) => {
    // Token from cookie or Bearer
    let token = req.cookies.token || req.headers.authorization;
    if (!token) {
      sendResponse.authError(res);
      return;
    }
    if (token.startsWith('Bearer ')) {
      token = token.slice(7, token.length);
    }
    try {
      const decoded = jwt.verify(
        token,
        config.JWT_SECRET
      ) as IAccessTokenPayload;
      if (!decoded || !decoded.id) {
        sendResponse.authError(res);
        return;
      }
      const user = await db.query(
        'SELECT * FROM user LEFT JOIN avatar ON avatar.userFk = user.id WHERE id = ?',
        [decoded.id]
      );
      if (user.length === 0) {
        sendResponse.authError(res);
        return;
      }
      // console.log(user);
      const { id, username, email, roleFk, generatedPath } = user[0];
      sendResponse.success(res, {
        id,
        username,
        email,
        roleFk,
        avatar: generatedPath,
      });
    } catch (err) {
      middleware.catchErrorExport(err, res);
    }
  },
};

/**
 *
 * @param {
 *   id: number,
 *   username: string,
 *   email: string,
 *   roleFk: number
 *   avatar: string
 *  } user
 * @param {*} res
 */
// interface User {
//   id: number;
//   username: string;
//   email: string;
//   roleFk: number;
//   generatedPath: string;
// }

class User {
  id: number;
  username: string;
  email: string;
  roleFk: number;
  avatar: string;
  constructor(
    id: number,
    username: string,
    email: string,
    roleFk: number,
    generatedPath: string
  ) {
    this.id = id;
    this.username = username;
    this.email = email;
    this.roleFk = roleFk;
    this.avatar = generatedPath;
  }
}

async function createAndSendTokens(res: Response, userId: number) {
  if (!userId) {
    return sendResponse.serverError(res);
  }
  const userDb = await db.query(
    'SELECT * FROM user LEFT JOIN avatar ON avatar.userFk = user.id WHERE id = ?',
    [userId]
  );

  if (userDb.length === 0) {
    return sendResponse.serverError(res);
  }
  delete userDb[0].password;
  const user: User = new User(
    userDb[0].id,
    userDb[0].username,
    userDb[0].email,
    userDb[0].roleFk,
    userDb[0].generatedPath
  );

  // Create Access Token
  const accessToken = jwt.sign(
    { id: user.id, username: user.username, email: user.email },
    config.JWT_SECRET,
    {
      // 10 minutes
      expiresIn: 10,
    }
  );
  // Create Refresh Token
  const refreshToken = crypto.randomBytes(64).toString('hex');
  // Store refresh token in redis
  // console.log('refreshToken', refreshToken);
  await redisClient.set(
    refreshToken,
    JSON.stringify({
      id: user.id,
      username: user.username,
      email: user.email,
      roleFk: user.roleFk,
      avatar: user.avatar,
    })
  );
  await redisClient.expire(refreshToken, 60 * 60 * 24 * 7);
  const csrfToken = jwt.sign({ id: user.id }, config.JWT_SECRET, {
    expiresIn: 60 * 60 * 24 * 7,
  });
  res.cookie('jwt', accessToken, {
    httpOnly: true,
    secure: process.env.MODE !== 'DEV',
    sameSite: 'strict',
    // Max age is 7 days
    maxAge: 1000 * 60 * 60 * 24 * 7,
  });
  sendResponse.success(res, {
    accessToken,
    refreshToken,
    csrfToken,
    user,
  });
}
export default AuthService;
