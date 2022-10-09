import { Response } from 'express';
import sendResponse from '../helpers/sendResponse';
import { IUserFromCookieInRequest } from '../types/express-custom';
import db from './db';
import * as redis from 'redis';
import config from '../config.json';
import moment from 'moment';
import * as OneSignal from '@onesignal/node-onesignal';

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

const redisClient = redis.createClient({
  url: ('redis://' + config.REDIS.host + ':' + config.REDIS.port).toString(),
  //   legacyMode: true,
});

redisClient.on('error', (err) => {
  console.log('Error ' + err);
});

redisClient.on('connect', () => {
  console.log('Connected to Redis');
});

redisClient.connect();
/*
"id": 11,
                "userFk": 1,
                "username": "skyface",
                "createdAt": "2022-10-03T19:55:03.000Z",
                "frontPath": "uploads/reals/uploadedImages-1664834103553.54.03.png",
                "backPath": "uploads/reals/uploadedImages-1664834103558.56.05.png",
                "timespan": 97415572
				*/
type Real = {
  id: number;
  userFk: number;
  username: string;
  createdAt: string; // Date
  frontPath: string;
  backPath: string;
  timespan: number;
};

type Friendship = {
  user: number;
  friend: number;
};

// Get lastRealTimestamp from Redis
async function getLastRealTimestamp() {
  const lastRealTimestampFromRedis = await redisClient.get('lastRealTimestamp');
  if (lastRealTimestampFromRedis) {
    // E.g 1664924762.14826
    const date = new Date(parseFloat(lastRealTimestampFromRedis) * 1000);
    return date.toISOString().replace('T', ' ').replace('Z', '');
  } else {
    return null;
  }
}

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
    const lastRealTimestamp = await getLastRealTimestamp();
    if (!lastRealTimestamp) {
      return sendResponse.success(res, {
        reals: [],
      });
    }
    console.log('lastRealTimestamp', lastRealTimestamp);

    // console.log('lastRealTimestamp', lastRealTimestamp);
    // Get the latest Reals of the friends
    const reals = await db.query(
      `select reals.id, reals.userFk, user.username, createdAt, frontPath, backPath, timespan FROM reals INNER JOIN (SELECT userFk, MAX(createdAt) AS latest FROM reals WHERE userFk IN (${friendIds.join(
        ',' // Not older than lastRealTimestamp
      )}) GROUP BY userFk) AS latestReals ON reals.userFk = latestReals.userFk AND reals.createdAt = latestReals.latest INNER JOIN user ON reals.userFk = user.id WHERE reals.createdAt >= str_to_date(?, '%Y-%m-%d %H:%i:%s')`,
      [lastRealTimestamp]
      //   [lastRealTimestamp.toString()]
    );
    if (!reals) {
      return sendResponse.success(res, {
        reals: [],
      });
    }
    // Timespan (bigint) to human readable
    const realsWithTimespan = reals.map((real: Real) => {
      return {
        ...real,
        timespanHuman: moment.duration(real.timespan, 'seconds').humanize(),
      };
    });

    console.log(reals.length);
    console.log(reals);
    sendResponse.success(res, { reals: realsWithTimespan });
  },
  uploadReal: async (req: IUserFromCookieInRequest, res: Response) => {
    const reqUser = req.user;
    // Multiple files with Multer
    const files = req.files as Express.Multer.File[];
    console.log('Files', files);
    if (!files) {
      return res.status(400).send('No files were uploaded.');
    }
    if (files.length !== 2) {
      res.status(400).send('Please upload 2 files');
      return;
    }
    const lastRealTimestamp = await getLastRealTimestamp();
    if (lastRealTimestamp == null) {
      res.status(400).send('Please wait for the next real');
      return;
    }
    // Front File
    const frontFile = files[0];
    const backFile = files[1];
    const uploadPath = 'uploads/reals';
    const frontPath = `${uploadPath}/${frontFile.filename}`;
    const backPath = `${uploadPath}/${backFile.filename}`;
    const timespanFromLastRealTimestamp = moment
      .duration(moment().diff(lastRealTimestamp))
      .asSeconds();

    //   new Date().getTime() - lastRealTimestamp.getTime();
    console.log('Timespan', timespanFromLastRealTimestamp);
    // Save to DB
    const result = await db.query(
      'INSERT INTO reals (userFk, frontPath, backPath, timespan) VALUES (?, ?, ?, ?)',
      [reqUser?.id, frontPath, backPath, timespanFromLastRealTimestamp]
    );

    console.log('Result', result);
    sendResponse.success(res, { message: 'Real uploaded' });

    // Send Push Notification to all friends
    const friends = await db.query(
      'select f1.* from friendship f1 inner join friendship f2 on f1.user = f2.friend and f1.friend = f2.user WHERE f1.user = ?',
      [reqUser?.id]
    );
    console.log('Friends', friends);
    // Array of non empty strings
    const friendIds = friends
      .map((friendship: Friendship) => {
        return friendship.friend.toString();
      })
      .filter((friendId: number) => {
        return friendId !== null;
      });
    console.log('Friend IDs', friendIds);

    const notification = new OneSignal.Notification();
    notification.app_id = ONESIGNAL_APP_ID;
    notification.include_external_user_ids = friendIds;
    notification.contents = {
      en: `${reqUser?.username} just uploaded a real`,
    };
    const { id } = await onesignalClient.createNotification(notification);
    console.log('Notification ID', id);
  },
  getOwnLatestRealFront: async (
    req: IUserFromCookieInRequest,
    res: Response
  ) => {
    const reqUser = req.user;
    const lastRealTimestamp = await getLastRealTimestamp();
    const latestRealForUser = await db.query(
      `SELECT * FROM reals WHERE userFk = ? AND createdAt >= ? ORDER BY createdAt DESC LIMIT 1`,
      [reqUser?.id, lastRealTimestamp]
    );
    if (latestRealForUser.length === 0 || !latestRealForUser[0]) {
      return sendResponse.success(res, { real: null });
    } else {
      console.log('Latest Real', latestRealForUser);
      res.sendFile(latestRealForUser[0].frontPath, {
        root: '.',
      });
    }
  },
  getOwnLatestRealBack: async (
    req: IUserFromCookieInRequest,
    res: Response
  ) => {
    const reqUser = req.user;
    const lastRealTimestamp = await getLastRealTimestamp();
    const latestRealForUser = await db.query(
      `SELECT * FROM reals WHERE userFk = ? AND createdAt >= ? ORDER BY createdAt DESC LIMIT 1`,
      [reqUser?.id, lastRealTimestamp]
    );
    if (latestRealForUser.length === 0 || !latestRealForUser[0]) {
      return sendResponse.success(res, { real: null });
    } else {
      console.log('Latest Real', latestRealForUser);
      res.sendFile(latestRealForUser[0].backPath, {
        root: '.',
      });
    }
  },
  getOwnLatestReal: async (req: IUserFromCookieInRequest, res: Response) => {
    const reqUser = req.user;
    const lastRealTimestamp = await getLastRealTimestamp();
    const latestRealForUser = await db.query(
      `SELECT * FROM reals WHERE userFk = ? AND createdAt >= str_to_date(?, '%Y-%m-%d %H:%i:%s') ORDER BY createdAt DESC LIMIT 1`,
      [reqUser?.id, lastRealTimestamp]
    );
    if (latestRealForUser.length === 0 || !latestRealForUser[0]) {
      return sendResponse.success(res, { real: null });
    } else {
      console.log('Latest Real', latestRealForUser);
      sendResponse.success(res, { real: latestRealForUser[0] });
    }
  },
  // const latestRealForUser = await db.query(
  //   `SELECT * FROM reals WHERE userFk = ? ORDER BY createdAt DESC LIMIT 1`,
  //   [reqUser?.id]
  // );
  // if (latestRealForUser.length === 0) {
  //   return sendResponse.success(res, { real: null });
  // } else {
  //   console.log('Latest Real', latestRealForUser);
  //   sendResponse.success(res, {
  //     real: latestRealForUser[0],
  //   });
  // }
  //   },
};
export default RealsService;
