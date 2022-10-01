import { AxiosResponse } from 'axios';
import React from 'react';
import { useParams } from 'react-router-dom';
import api from '../../services/api';
import Disable2FA from './disable2FA';
import Enable2FA from './enable2FA';
import { AuthContext } from '../../App';
import { useContext } from 'react';
import AvatarUpload from './avatarUpload';
import { ActionType } from '../../store/reducer';

interface IUserSettings {
  twoFactorEnabled: boolean;
  username: string;
  email: string;
}

export default function SettingsPage() {
  const { state, dispatch } = useContext(AuthContext);
  const [user, setUser] = React.useState<IUserSettings>();
  const [error, setError] = React.useState('');
  let { settingSection } = useParams();

  async function loadUserSettings() {
    try {
      api
        .get('/user/settings')
        .then((res: AxiosResponse) => {
          setUser(res.data.data);
        })
        .catch((err: any) => {
          setError(err.response.data.message);
        });
    } catch (err) {
      setError((err as any).response.data.data);
    }
  }

  React.useEffect(() => {
    loadUserSettings();
  }, []);
  if (error) {
    return <div>{error}</div>;
  }

  if (settingSection === 'disable2fa') {
    return <Disable2FA />;
  } else if (settingSection === 'enable2fa') {
    return <Enable2FA />;
  } else if (settingSection === 'avatar') {
    return (
      <AvatarUpload
        currentFile={null}
        progress={0}
        message={''}
        fileInfos={undefined}
        changeAvatarCallback={(avatar: string) => {
          dispatch({
            type: ActionType.CHANGE_AVATAR,
            payload: {
              avatar: avatar,
            },
          });
        }}
      />
    );
  }

  if (!user) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h1>Settings</h1>
      <p>Change your settings here.</p>
      <div>
        <h2>Security</h2>
        <p>Change your security settings here.</p>
        <div>
          <h3>2FA</h3>
          <p>Change your 2FA settings here.</p>

          <div>
            <h4>Current 2FA Status</h4>
            <p>{user.twoFactorEnabled ? 'Enabled' : 'Disabled'}</p>
            <button
              onClick={() => {
                console.log('Clicked');
                if (user.twoFactorEnabled) {
                  window.location.href = '/settings/disable2fa';
                } else {
                  window.location.href = '/settings/enable2fa';
                }
              }}
            >
              {user.twoFactorEnabled ? 'Disable 2FA' : 'Enable 2FA'}
            </button>
          </div>
        </div>
        <h2>Account</h2>
        <p>Change your account settings here.</p>
        <div>
          <h3>Avatar</h3>
          <p>Change your avatar here.</p>
          <div>
            <a href='/settings/avatar'>Change Avatar</a>
          </div>
          <h3>Username</h3>
          <p>Change your username here.</p>
          <div>
            <h4>Current Username</h4>
            <p>{user.username}</p>
            <h4>New Username</h4>
            <input type='text' />
            <button>Change Username</button>
          </div>
          <h3>Email</h3>
          <p>Change your email here.</p>
          <div>
            <h4>Current Email</h4>
            <p>{user.email}</p>
            <h4>New Email</h4>
            <input type='text' />
            <button>Change Email</button>
          </div>
          <h3>Password</h3>
          <p>Change your password here.</p>
          <div>
            <h4>Current Password</h4>
            <input type='password' />
            <h4>New Password</h4>
            <input type='password' />
            <h4>Confirm New Password</h4>
            <input type='password' />
            <button>Change Password</button>
          </div>
        </div>
      </div>
    </div>
  );
}
