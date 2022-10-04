import { Response } from 'express';
import sendResponse from '../helpers/sendResponse';
import { IUserFromCookieInRequest } from '../types/express-custom';
import db from './db';
import fs from 'fs';
import * as OneSignal from '@onesignal/node-onesignal';
import * as redis from 'redis';
import config from '../config.json';
import moment from 'moment';
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

function createNewRandomDate() {
  // Create new time between tomorrow 10am and 11:59
  const start = new Date();
  start.setDate(start.getDate() + 1);
  start.setHours(10);
  start.setMinutes(0);
  start.setSeconds(0);
  const end = new Date();
  end.setDate(end.getDate() + 1);
  end.setHours(23);
  end.setMinutes(59);
  end.setSeconds(59);
  //   DEV - 30 seconds
  //   const start = new Date();
  //   start.setSeconds(start.getSeconds() + 100);
  //   const end = new Date();
  //   end.setSeconds(end.getSeconds() + 200);
  const newDate = new Date(
    start.getTime() + Math.random() * (end.getTime() - start.getTime())
  );
  return newDate;
}

let lastRealTimestamp: Date | null = null;
let nextRealTimestamp: Date | null = null;
async function realsTime() {
  const isMasterNode =
    process.env.MODE === 'master' || process.env.MODE === 'DEV';
  if (isMasterNode) {
    console.log('IS MASTER NODE - MANAGES AND PUSH REALS TIME');
  }
  const interval = setInterval(async () => {
    // Get lastRealTimestamp from Redis
    const lastRealTimestampFromRedis = await redisClient.get(
      'lastRealTimestamp'
    );
    const nextRealTimestampFromRedis = await redisClient.get(
      'nextRealTimestamp'
    );
    if (!nextRealTimestampFromRedis) {
      if (isMasterNode) {
        nextRealTimestamp = createNewRandomDate();
        await redisClient.set(
          'nextRealTimestamp',
          nextRealTimestamp.toString()
        );
      }
    } else {
      nextRealTimestamp = new Date(nextRealTimestampFromRedis);
      if (isMasterNode && new Date() > nextRealTimestamp) {
        lastRealTimestamp = nextRealTimestamp;
        nextRealTimestamp = createNewRandomDate();
        await redisClient.set(
          'nextRealTimestamp',
          nextRealTimestamp.toString()
        );
        await redisClient.set(
          'lastRealTimestamp',
          lastRealTimestamp.toString()
        );
        // Send Push to Clients
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
        const client = new OneSignal.DefaultApi(configuration);

        const notification = new OneSignal.Notification();
        notification.app_id = ONESIGNAL_APP_ID;
        notification.included_segments = ['Subscribed Users'];
        notification.contents = {
          en: 'Time for a new real!',
        };
        const { id } = await client.createNotification(notification);
        console.log('Notification sent: ' + id);
      }
    }
    // const humanReadableLastRealTimestamp = lastRealTimestamp?.toLocaleString();
    // const humanReadableNextRealTimestamp = nextRealTimestamp?.toLocaleString();
    // console.log(
    //   `lastRealTimestamp: ${humanReadableLastRealTimestamp} - nextRealTimestamp: ${humanReadableNextRealTimestamp}`
    // );
    if (lastRealTimestampFromRedis) {
      lastRealTimestamp = new Date(lastRealTimestampFromRedis);
    } else {
      lastRealTimestamp = null;
    }
  }, 1000);
}

realsTime();

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
    if (!lastRealTimestamp) {
      return sendResponse.success(res, {
        reals: [],
      });
    }
    // lastRealTimestamp (2022-10-03T21:22:17.000Z) to format 2022-10-03 20:52:11
    const lastRealTimestampFormatted = lastRealTimestamp
      .toISOString()
      .replace('T', ' ')
      .replace('Z', '');

    // console.log('lastRealTimestamp', lastRealTimestamp);
    // Get the latest Reals of the friends
    const reals = await db.query(
      `select reals.id, reals.userFk, user.username, createdAt, frontPath, backPath, timespan FROM reals INNER JOIN (SELECT userFk, MAX(createdAt) AS latest FROM reals WHERE userFk IN (${friendIds.join(
        ',' // Not older than lastRealTimestamp
      )}) GROUP BY userFk) AS latestReals ON reals.userFk = latestReals.userFk AND reals.createdAt = latestReals.latest INNER JOIN user ON reals.userFk = user.id WHERE reals.createdAt >= str_to_date(?, '%Y-%m-%d %H:%i:%s')`,
      [lastRealTimestampFormatted]
      //   [lastRealTimestamp.toString()]
    );
    // Timespan (bigint) to human readable
    const realsWithTimespan = reals.map((real: Real) => {
      return {
        ...real,
        timespan: moment.duration(real.timespan, 'seconds').humanize(),
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
  },
  getOwnLatestRealFront: async (
    req: IUserFromCookieInRequest,
    res: Response
  ) => {
    const reqUser = req.user;
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
    const latestRealForUser = await db.query(
      `SELECT * FROM reals WHERE userFk = ? ORDER BY createdAt DESC LIMIT 1`,
      [reqUser?.id]
    );
    if (latestRealForUser.length === 0) {
      return sendResponse.success(res, { real: null });
    } else {
      console.log('Latest Real', latestRealForUser);
      sendResponse.success(res, {
        real: latestRealForUser[0],
      });
    }
  },
};
export default RealsService;
