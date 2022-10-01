import { useState, useContext, useEffect } from 'react';
import { useLocation, Navigate, Outlet } from 'react-router-dom';
import { AuthContext } from '../App';
import React from 'react';
import api from '../services/api';

const access = async () => {
  const response = await api.get('auth/status');
  console.log('After /auth/status');
  if (!response) {
    return false;
  }
  console.log(response);
  if (response.data.success) {
    return true;
  } else {
    return false;
  }
  // return await axios.post(
  //   "http://localhost:5000/access",
  //   {},
  //   { headers: { Authorization: `Bearer ${token}` } }
  // );
};

export const UserProtectedRoute = () => {
  const location = useLocation();
  const [authorized, setAuthorized] = useState<boolean>(); // initially undefined!

  const { state } = useContext(AuthContext);

  useEffect(() => {
    const authorize = async () => {
      try {
        setAuthorized(await access());
      } catch (err) {
        setAuthorized(false);
      }
    };

    authorize();
  }, []);

  if (authorized === undefined) {
    return null; // or loading indicator/spinner/etc
  }

  return authorized ? (
    <Outlet />
  ) : (
    <Navigate to='/login' replace state={{ from: location }} />
  );
};
