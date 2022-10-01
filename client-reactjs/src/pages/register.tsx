import React, { useContext } from 'react';
import '../styles/sign-up-and-in.css';
import { AuthContext } from '../App';
import { uninterceptedAxiosInstance } from '../services/api';
import { ActionType } from '../store/reducer';
// import GitHubLoginButton from "../components/GitHubLoginButton";

export default function Register() {
  const { dispatch } = useContext(AuthContext);
  var lastPage = document.referrer;
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [confirmPassword, setConfirmPassword] = React.useState('');
  const [error, setError] = React.useState('');

  async function register() {
    if (!email || !password || !confirmPassword) {
      setError('Please fill in all fields');
      return;
    }
    // Check if password contains at least 8 characters, one uppercase, one lowercase, one number and one special character
    if (
      !password.match(/^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$/gm)
    ) {
      setError(
        'Password must contain at least 8 characters, one uppercase, one lowercase, one number and one special character'
      );
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters long');
      return;
    }
    uninterceptedAxiosInstance
      .put('auth/register', {
        email,
        password,
      })
      .then((res) => {
        console.log(res);
        if (res.data.success) {
          console.log(res.data.data.user);
          dispatch({
            type: ActionType.LOGIN,
            payload: {
              user: res.data.data.user,
              isLoggedIn: true,
            },
          });
          window.alert('You have successfully registered!');
          window.location.href = lastPage;
        } else {
          setError(res.data);
        }
      })
      .catch((err) => {
        setError(err.response.data.data);
      });
  }

  return (
    <div>
      <div className='sign-in-up-container'>
        <div>
          <h1 className='site-title'>Sign Up</h1>
          <p>Please fill in this form to create an account.</p>
          <hr />

          <label htmlFor='email'>
            <b>Email</b>
          </label>
          <input
            type='text'
            placeholder='Enter Email'
            name='email'
            required
            value={email}
            onChange={(e) => {
              setEmail(e.target.value);
              // TODO: check if email is free
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                register();
              }
            }}
          />

          <label htmlFor='password'>
            <b>Password</b>
          </label>
          <input
            type='password'
            placeholder='Enter Password'
            name='password'
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                register();
              }
            }}
          />

          <label htmlFor='confirmPassword'>
            <b>Confirm Password</b>
          </label>
          <input
            type='password'
            placeholder='Confirm Password'
            name='confirmPassword'
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                register();
              }
            }}
          />

          <p
            style={{
              color: 'red',
            }}
          >
            {error}
          </p>

          <p>
            By creating an account you agree to our{' '}
            <a href='/privacy-policy' style={{ color: 'dodgerblue' }}>
              Terms & Privacy
            </a>
            .
          </p>

          <div className='clearfix'>
            <button
              type='submit'
              className='sign-in-up-btn'
              onClick={() => {
                register();
              }}
            >
              Sign Up
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
