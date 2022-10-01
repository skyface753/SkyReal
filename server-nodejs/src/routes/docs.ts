// Imports

import express from 'express';
import swaggerDocsObj from '../swagger'; // Swagger docs
const router = express.Router();
router.use('/', swaggerDocsObj.serve, swaggerDocsObj.setup);
export default router;
