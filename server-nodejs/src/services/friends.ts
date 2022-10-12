import { Response } from 'express';
import db from './db';
import sendResponse from '../helpers/sendResponse';
import { IUserFromCookieInRequest } from '../types/express-custom';
import * as OneSignal from '@onesignal/node-onesignal';
import config from '../config.json';
import { FriendStatus, UserResponse } from './search';
const ONESIGNAL_APP_ID = config.OneSignal.appID;

const app_key_provider = {
  getToken() {
    return config.OneSignal.restAPIKey;
  },
};

const configuration = OneSignal.createConfiguration({
  authMethods: {
    app_key: {
      tokenProvider: app_key_provider,
    },
  },
});
const onesignalClient = new OneSignal.DefaultApi(configuration);
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
      return sendResponse.error(res, 'You cannot add yourself as a friend');
    }
    // Check if recipient exists
    const recipientExists = await db.query('SELECT * FROM user WHERE id = ?', [
      recipient,
    ]);
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
      return sendResponse.success(res, 'Already sent a friend request');
    }
    if (fromRecipientToUser && fromRecipientToUser.length) {
      // Accept friend request
      await db.query('INSERT INTO friendship (user, friend) VALUES (?, ?)', [
        id,
        recipient,
      ]);
      try {
        const notification = new OneSignal.Notification();
        notification.app_id = ONESIGNAL_APP_ID;
        notification.include_external_user_ids = [recipient.toString()];
        notification.contents = {
          en: `${req.user?.username} just accepted your friend request`,
        };
        const idAccept = await (
          await onesignalClient.createNotification(notification)
        ).id;
        console.log('Notification ID', idAccept);
      } catch (e) {
        console.log(e);
      }
      return sendResponse.success(res, 'Friend request accepted');
    }
    // Send friend request
    await db.query('INSERT INTO friendship (user, friend) VALUES (?, ?)', [
      id,
      recipient,
    ]);
    const notification = new OneSignal.Notification();
    notification.app_id = ONESIGNAL_APP_ID;
    notification.include_external_user_ids = [recipient.toString()];
    notification.contents = {
      en: `${req.user?.username} just sent you a friend request`,
    };
    const idSend = await (
      await onesignalClient.createNotification(notification)
    ).id;
    console.log('Notification ID', idSend);
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
      return sendResponse.error(res, 'You cannot remove yourself as a friend');
    }
    // Check if otherUserId exists
    const otherUserExists = await db.query('SELECT * FROM user WHERE id = ?', [
      recipient,
    ]);
    if (!otherUserExists || !otherUserExists.length) {
      return sendResponse.error(res, 'User not found');
    }
    // Remove from user to otherUserId and otherUserId to user
    await db.query('DELETE FROM friendship WHERE user = ? AND friend = ?', [
      id,
      recipient,
    ]);
    await db.query('DELETE FROM friendship WHERE user = ? AND friend = ?', [
      recipient,
      id,
    ]);
    return sendResponse.success(res, 'Friend removed');
  },

  getAll: async (req: IUserFromCookieInRequest, res: Response) => {
    if (!req.user) {
      return sendResponse.authError(res);
    }
    const { id } = req.user;
    const friends = await db.query(
      'SELECT user.id, user.username FROM friendship JOIN user ON user.id = friendship.friend WHERE friendship.user = ?',
      [id]
    );
    const friendsResponse: UserResponse[] = friends.map(
      (user: UserResponse) => ({
        ...user,
        friendship: FriendStatus.FRIENDS,
      })
    );
    return sendResponse.success(res, friendsResponse);
  },
  getIncomingFriendRequests: async (
    req: IUserFromCookieInRequest,
    res: Response
  ) => {
    if (!req.user) {
      return sendResponse.authError(res);
    }
    const result = await db.query(
      'SELECT user.id, user.username FROM friendship JOIN user ON user.id = friendship.user WHERE friendship.friend = ?',
      [req.user.id]
    );
    if (!result || !result.length) {
      return sendResponse.success(res, 'No friend requests');
    }
    const userResponse: UserResponse[] = result.map((user: UserResponse) => ({
      ...user,
      friendship: FriendStatus.PENDINGIN,
    }));
    return sendResponse.success(res, userResponse);
  },
};

export default FriendsService;
