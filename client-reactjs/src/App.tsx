import Navbar from './components/Navbar';
import Footer from './components/Footer';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { initialState, reducer, IAuthState, IAction } from './store/reducer';
import React, { createContext, useReducer } from 'react';
import UseGaTracker from './useGATracker';
import CookieConsent from 'react-cookie-consent';

import './App.css';
import { UserProtectedRoute } from './helpers/UserRouteProtector';
import Home from './pages/home';
import Login from './pages/login';
import Register from './pages/register';
import StatusPage from './pages/status';
import NotFound from './pages/notFound';
import SettingsPage from './pages/settings';

// export const AuthContext = createContext<any>(initialState);

export const AuthContext = createContext<{
  state: IAuthState;
  dispatch: React.Dispatch<IAction>;
}>({ state: initialState, dispatch: () => {} });

function App() {
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <AuthContext.Provider
      value={{
        state,
        dispatch,
      }}
    >
      {/* <GoogleOAuthProvider clientId={config.clientId}> */}
      <Router>
        <UseGaTracker />
        <CookieConsent
          acceptOnScroll={false}
          onDecline={() => {
            //console.log("Cookie declined");
            window.location.reload();
          }}
          enableDeclineButton={true}
          buttonText='I accept'
        >
          This website uses technical necessary cookies to ensure the login. You
          can accept or decline the analytics cookies.
          <a href='privacy-policy'>Privacy Policy</a>
        </CookieConsent>
        <Navbar />
        <div className='main-div'>
          <Routes>
            <Route path='/' element={<Home />} />
            <Route path='/home' element={<Home />} />
            <Route path='/register' element={<Register />} />
            <Route path='/login' element={<Login />} />

            <Route element={<UserProtectedRoute />}>
              {/* User Protected Route - redirect to login page */}
              <Route path='/status' element={<StatusPage />} />
              <Route path='/settings' element={<SettingsPage />} />
              <Route
                path='/settings/:settingSection'
                element={<SettingsPage />}
              />
              {/* <Route path='/settings/' */}
            </Route>
            <Route path='*' element={<NotFound />} />
          </Routes>
        </div>
        <Footer />
      </Router>
      {/* </GoogleOAuthProvider> */}
    </AuthContext.Provider>
  );
}

export default App;
