// const { checkTokenInRedis } = require('./helpers/redis_helper');
import { Response, NextFunction } from 'express';

// const sendResponse = require('./helpers/sendResponse');
import sendResponse from './helpers/sendResponse';
// const tokenHelper = require('./helpers/token');
// const db = require('./services/db.js');
// const jwt = require('jsonwebtoken');
// const config = require('./config.json');
import db from './services/db';
import jwt from 'jsonwebtoken';
import config from './config.json';
import { IUserFromCookieInRequest } from './types/express-custom';
import { IAccessTokenPayload } from './types/jwt-payload';

export default {
	// const Middlewargcce = {
	authUser: async (
		req: IUserFromCookieInRequest,
		res: Response,
		next: NextFunction
	) => {
		const token = req.cookies.jwt;
		if (!token) {
			console.log('No token');
			return sendResponse.authError(res);
		}
		try {
			const payload = jwt.verify(
				token,
				config.JWT_SECRET
			) as IAccessTokenPayload;
			if (!payload) {
				console.log('No payload');
				return sendResponse.authError(res);
			}
			const user = await db.query(
				'SELECT * FROM user WHERE id = ?',
				[payload.id]
			);
			if (user.length === 0) {
				console.log('No user');
				return sendResponse.authError(res);
			}
			req.user = user[0];
			next();
		} catch (err) {
			catchError(err, res);
		}
	},
	authAdmin: async (
		req: IUserFromCookieInRequest,
		res: Response,
		next: NextFunction
	) => {
		const token = req.cookies.jwt;
		if (!token) {
			return sendResponse.authError(res);
		}
		try {
			const payload = jwt.verify(
				token,
				config.JWT_SECRET
			) as IAccessTokenPayload;
			if (!payload) {
				return sendResponse.authError(res);
			}
			const user = await db.query(
				'SELECT * FROM user WHERE id = ?',
				[payload.id]
			);
			if (user.length === 0) {
				return sendResponse.authError(res);
			}
			if (user[0].roleFk !== 2) {
				return sendResponse.authAdminError(res);
			}
			req.user = user[0];
			next();
		} catch (err) {
			catchError(err, res);
		}
	},
	catchErrorExport: async (err: unknown, res: Response) => {
		catchError(err, res);
	},
	csrfValidation: async (
		req: IUserFromCookieInRequest,
		res: Response,
		next: NextFunction
	) => {
		const csrfTokenInHeader = req.headers['x-csrf-token'] as string;
		try {
			if (!csrfTokenInHeader) {
				return sendResponse.authError(res);
			}
			const payload = jwt.verify(
				csrfTokenInHeader,
				config.JWT_SECRET
			);
			if (!payload) {
				return sendResponse.authError(res);
			}

			next();
		} catch (err) {
			if (err instanceof jwt.TokenExpiredError) {
				return sendResponse.authError(res);
			} else if (err instanceof jwt.JsonWebTokenError) {
				return sendResponse.authError(res);
			}
			return sendResponse.serverError(res);
		}
	},
};

const catchError = (err: unknown, res: Response) => {
	if (err instanceof jwt.TokenExpiredError) {
		console.log('Token expired');
		return sendResponse.expiredToken(res);
	} else if (err instanceof jwt.JsonWebTokenError) {
		console.log('JsonWebTokenError');
		return sendResponse.authError(res);
	}
	if (err instanceof jwt.JsonWebTokenError) {
		console.log('JsonWebTokenError');
		sendResponse.authError(res);
		return;
	}
	console.log('Server error');
	sendResponse.serverError(res);
	return;
};
