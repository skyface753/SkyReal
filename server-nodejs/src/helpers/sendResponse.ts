/* eslint-disable @typescript-eslint/no-explicit-any */
import { Response } from 'express';

const sendResponse = {
	success: (res: Response, data: any) => {
		res.status(200).json({
			success: true,
			data: data,
		});
	},
	missingParams: (res: Response) => {
		res.status(400).json({
			success: false,
			message: 'Missing Parameters',
		});
	},
	error: (res: Response, message = 'Error') => {
		console.trace();

		res.status(400).json({
			success: false,
			message: message,
		});
	},

	expiredToken: (res: Response) => {
		res.status(401).json({
			success: false,
			message: 'jwt expired',
		});
	},

	authError: (res: Response) => {
		console.trace('authError');
		res.status(401).json({
			success: false,
			message: 'Access Denied - Not Authorized',
		});
	},
	authAdminError: (res: Response) => {
		res.status(403).json({
			success: false,
			message: 'Access Denied - Admin Only',
		});
	},
	serverError: (res: Response) => {
		res.status(500).json({
			success: false,
			message: 'Server Error',
		});
	},
};

export default sendResponse;
