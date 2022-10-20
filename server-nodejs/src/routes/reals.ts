import express from 'express';
const router = express.Router();
import RealsService from '../services/reals';
import Middleware from '../middleware';
import multer from 'multer';
import path from 'path';

router.get('/', Middleware.authUser, RealsService.getReals);

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '../../uploads/reals'));
  },
  filename: function (req, file, cb) {
    cb(
      null,
      file.fieldname +
        '-' +
        Date.now() +
        file?.originalname?.match(/\..*$/)?.[0]
    );
  },
});
const multi_upload = multer({
  storage,
  limits: { fileSize: 1 * 1024 * 1024 }, // 1MB
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype == 'image/png' ||
      file.mimetype == 'image/jpg' ||
      file.mimetype == 'image/jpeg' ||
      file.mimetype == 'application/octet-stream'
    ) {
      cb(null, true);
    } else {
      cb(null, false);
      const err = new Error(
        'Only .png, .jpg and .jpeg format allowed!: ' + file.mimetype
      );
      err.name = 'ExtensionError';
      return cb(err);
    }
  },
}).array('uploadedImages', 2);
router.put(
  '/upload',

  Middleware.authUser,
  multi_upload,
  RealsService.uploadReal
);
// router.get(
//   '/own/front',
//   Middleware.authUser,
//   RealsService.getOwnLatestRealFront
// );
// router.get('/own/back', Middleware.authUser, RealsService.getOwnLatestRealBack);
router.get('/own', Middleware.authUser, RealsService.getOwnLatestReal);
router.get('/own/all', Middleware.authUser, RealsService.getAllOwn);
export default router;
