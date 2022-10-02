import { Response } from 'express';
import sendResponse from '../helpers/sendResponse';
import { IUserFromCookieInRequest } from '../types/express-custom';
import db from './db';
import fs from 'fs';

type Real = {
	id: number;
	userFk: number;
	path: string;
	createdAt: Date; // TimeStamp from MySQL
};

type Friendship = {
	user: number;
	friend: number;
};
const RealsService = {
	getReals: async (req: IUserFromCookieInRequest, res: Response) => {
		const reqUser = req.user;
		console.log('ID', reqUser?.id);
		// Get Friends of the user
		const friends = await db.query(
			'select f1.* from friendship f1 inner join friendship f2 on f1.user = f2.friend and f1.friend = f2.user WHERE f1.user = ?',
			[reqUser?.id]
		);
		console.log('Friends', friends);
		const friendIds = friends.map((friendship: Friendship) => {
			return friendship.friend;
		});
		console.log('Friend IDs', friendIds);
		// Get the latest Reals of the friends
		const reals = await db.query(
			`select reals.id, reals.userFk, user.username, createdAt, frontPath, backPath FROM reals INNER JOIN (SELECT userFk, MAX(createdAt) AS latest FROM reals WHERE userFk IN (${friendIds.join(
				','
			)}) GROUP BY userFk) AS latestReals ON reals.userFk = latestReals.userFk AND reals.createdAt = latestReals.latest INNER JOIN user ON reals.userFk = user.id`,
			[]
		);

		console.log(reals.length);
		console.log(reals);
		sendResponse.success(res, { reals: reals });
	},
	uploadReal: async (req: IUserFromCookieInRequest, res: Response) => {
		const reqUser = req.user;
		// Multiple files with Multer
		const files = req.files as Express.Multer.File[];
		console.log('Files', files);
		// Front File
		const frontFile = files[0];
		const backFile = files[1];
		const uploadPath = 'uploads/reals';
		const frontPath = `${uploadPath}/${frontFile.filename}`;
		const backPath = `${uploadPath}/${backFile.filename}`;
		// Save to DB
		const result = await db.query(
			'INSERT INTO reals (userFk, frontPath, backPath) VALUES (?, ?, ?)',
			[reqUser?.id, frontPath, backPath]
		);
		console.log('Result', result);
		sendResponse.success(res, { message: 'Real uploaded' });
	},
};
export default RealsService;
