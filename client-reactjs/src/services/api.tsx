import axios from 'axios';
import { setupInterceptorsTo } from './interceptors';
import config from '../config.json';

axios.defaults.withCredentials = true;

const api = setupInterceptorsTo(
  axios.create({
    baseURL: config.BackendUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  })
);

export const uninterceptedAxiosInstance = axios.create({
  baseURL: config.BackendUrl,
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;
