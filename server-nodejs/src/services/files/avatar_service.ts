import sendResponse from '../../helpers/sendResponse';
import db from '../db';
import config from '../../config.json';
import fs from 'fs';
import { Request, Response } from 'express';
import { IUserFromCookieInRequest } from '../../types/express-custom';
interface MulterRequest extends Request {
  file: Express.Multer.File;
}

const AvatarService = {
  uploadAvatar: async (req: IUserFromCookieInRequest, res: Response) => {
    const file = (req as MulterRequest).file;
    if (!file) {
      sendResponse.missingParams(res);
      return;
    }
    const user = req.user;
    const originalName = file.originalname;
    const generatedPath = config.files.avatarDir + file.filename;
    const type = file.mimetype;

    const avatarExists = await db.query(
      'SELECT * FROM avatar WHERE userFk = ?',
      [user?.id]
    );
    let result;
    if (avatarExists.length > 0) {
      try {
        fs.unlinkSync(avatarExists[0].generatedPath);
      } catch (e) {
        console.log(e);
      }
      result = await db.query(
        'UPDATE avatar SET originalName = ?, generatedPath = ?, type = ? WHERE userFk = ?',
        [originalName, generatedPath, type, user?.id]
      );
    } else {
      result = await db.query(
        'INSERT INTO avatar (originalName, generatedPath, type, userFk) VALUES (?, ?, ?, ?)',
        [originalName, generatedPath, type, user?.id]
      );
    }
    if (!result) {
      sendResponse.error(res);
      return;
    }
    sendResponse.success(res, {
      message: 'Avatar uploaded',
      avatar: {
        originalName: originalName,
        generatedPath: generatedPath,
        type: type,
        userFk: user?.id,
      },
    });
  },
  deleteAvatar: async (req: IUserFromCookieInRequest, res: Response) => {
    const user = req.user;
    let avatar = await db.query('SELECT * FROM avatar WHERE userFk = ?', [
      user?.id,
    ]);
    if (avatar.length === 0) {
      sendResponse.error(res);
      return;
    }
    avatar = avatar[0];
    const result = await db.query('DELETE FROM avatar WHERE userFk = ?', [
      user?.id,
    ]);
    if (!result) {
      sendResponse.error(res);
      return;
    }
    fs.unlink(avatar.generatedPath, (err) => {
      if (err) {
        console.log(err);
      }
    });
    sendResponse.success(res, {
      message: 'Avatar deleted',
    });
  },
};
export default AvatarService;
