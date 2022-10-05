import { Response } from 'express';
import db from './db';
import sendResponse from '../helpers/sendResponse';
import { IUserFromCookieInRequest } from '../types/express-custom';

/**
 * DB Table: friendship
 * Columns: user, friend
 * When user -> friend and friend -> user => friends
 * When user -> friend but not friend -> user => pending
 **/
const FriendsService = {
	add: async (req: IUserFromCookieInRequest, res: Response) => {
		const { recipient } = req.body;
		if (!req.user) {
			return sendResponse.authError(res);
		}
		const { id } = req.user;
		if (!recipient) {
			return sendResponse.missingParams(res);
		}
		if (recipient == id) {
			return sendResponse.error(
				res,
				'You cannot add yourself as a friend'
			);
		}
		// Check if recipient exists
		const recipientExists = await db.query(
			'SELECT * FROM user WHERE id = ?',
			[recipient]
		);
		if (!recipientExists || !recipientExists.length) {
			return sendResponse.error(res, 'User not found');
		}
		// Check if from user to recipient exists
		const fromUserToRecipient = await db.query(
			'SELECT * FROM friendship WHERE user = ? AND friend = ?',
			[id, recipient]
		);
		// Check if from recipient to user exists
		const fromRecipientToUser = await db.query(
			'SELECT * FROM friendship WHERE user = ? AND friend = ?',
			[recipient, id]
		);
		if (
			fromUserToRecipient &&
			fromUserToRecipient.length &&
			fromRecipientToUser &&
			fromRecipientToUser.length
		) {
			return sendResponse.success(res, 'Already friends');
		}
		if (fromUserToRecipient && fromUserToRecipient.length) {
			return sendResponse.success(
				res,
				'Already sent a friend request'
			);
		}
		if (fromRecipientToUser && fromRecipientToUser.length) {
			// Accept friend request
			await db.query(
				'INSERT INTO friendship (user, friend) VALUES (?, ?)',
				[id, recipient]
			);
			return sendResponse.success(
				res,
				'Friend request accepted'
			);
		}
		// Send friend request
		await db.query(
			'INSERT INTO friendship (user, friend) VALUES (?, ?)',
			[id, recipient]
		);
		return sendResponse.success(res, 'Friend request sent');
	},
	remove: async (req: IUserFromCookieInRequest, res: Response) => {
		const { recipient } = req.body;
		if (!req.user) {
			return sendResponse.authError(res);
		}
		const { id } = req.user;
		if (!recipient) {
			return sendResponse.missingParams(res);
		}
		if (recipient == id) {
			return sendResponse.error(
				res,
				'You cannot remove yourself as a friend'
			);
		}
		// Check if otherUserId exists
		const otherUserExists = await db.query(
			'SELECT * FROM user WHERE id = ?',
			[recipient]
		);
		if (!otherUserExists || !otherUserExists.length) {
			return sendResponse.error(res, 'User not found');
		}
		// Remove from user to otherUserId and otherUserId to user
		await db.query(
			'DELETE FROM friendship WHERE user = ? AND friend = ?',
			[id, recipient]
		);
		await db.query(
			'DELETE FROM friendship WHERE user = ? AND friend = ?',
			[recipient, id]
		);
		return sendResponse.success(res, 'Friend removed');
	},
};

export default FriendsService;
