import React from 'react';
import ProfilePictureComponent from '../components/ProfilePicture';
import api from '../services/api';

interface IAuthStatusState {
  success: boolean;
  data: {
    id: number;
    username: string;
    email: string;
    avatar: string;
    roleFk: number;
  } | null;
}

export default function StatusPage() {
  const [authStatus, setAuthStatus] = React.useState<IAuthStatusState>({
    success: false,
    data: null,
  });

  React.useEffect(() => {
    api.get('auth/status').then((res) => {
      setAuthStatus(res.data);
    });
  }, []);

  if (!authStatus.success) {
    // Show loading indicator
    return <div>Loading...</div>;
  }

  return (
    <div className='status-container'>
      <h1>Status</h1>
      <ProfilePictureComponent avatarPath={authStatus.data?.avatar} />
      <p>Success: {authStatus.success ? 'true' : 'false'}</p>
      <p>Username: {authStatus.data?.username}</p>
      <p>Email: {authStatus.data?.email}</p>

      <p>Role: {authStatus.data?.roleFk}</p>
    </div>
  );
}
