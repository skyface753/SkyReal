export enum ActionType {
  LOGIN = 'LOGIN',
  LOGOUT = 'LOGOUT',
  CHANGE_USERNAME = 'CHANGE_USERNAME',
  CHANGE_AVATAR = 'CHANGE_AVATAR',
}

export interface IAction {
  type: ActionType;
  payload: any;
}

interface IUser {
  id: number;
  username: string;
  email: string;
  avatar: string;
  roleFk: number;
}

export interface IAuthState {
  isLoggedIn: boolean;
  user: IUser | null;
  accessToken: string | null;
  refreshToken: string | null;
  csrfToken: string | null;
}

export const initialState = {
  isLoggedIn: localStorage.getItem('isLoggedIn') === 'true',
  user: localStorage.getItem('user')
    ? JSON.parse(localStorage.getItem('user') as string)
    : null,
  accessToken: localStorage.getItem('accessToken'),
  refreshToken: localStorage.getItem('refreshToken'),
  csrfToken: localStorage.getItem('csrfToken'),
};

export const reducer = (state: IAuthState, action: IAction) => {
  const { type, payload } = action;
  switch (type) {
    case ActionType.LOGIN: {
      const { user, accessToken, refreshToken, csrfToken } = payload;
      localStorage.setItem('isLoggedIn', JSON.stringify(true));
      localStorage.setItem('user', JSON.stringify(user));
      localStorage.setItem('accessToken', JSON.stringify(accessToken));
      localStorage.setItem('refreshToken', JSON.stringify(refreshToken));
      localStorage.setItem('csrfToken', JSON.stringify(csrfToken));
      return {
        ...state,
        isLoggedIn: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        csrfToken: csrfToken,
      };
    }
    case ActionType.LOGOUT: {
      //TODO clear local storage specific
      localStorage.clear();
      return {
        ...state,
        isLoggedIn: false,
        user: null,
        accessToken: null,
        refreshToken: null,
        csrfToken: null,
      };
    }
    case ActionType.CHANGE_USERNAME: {
      const { username } = payload;
      // TODO: update local storage
      if (localStorage.getItem('user')) {
        const user = JSON.parse(localStorage.getItem('user')!);
        user.username = username;
        localStorage.setItem('user', JSON.stringify(user));
      }

      return {
        ...state,
        user: {
          ...state.user,
          username: username,
        },
      };
    }
    case ActionType.CHANGE_AVATAR: {
      const { avatar } = payload; // Avatar as URL
      if (localStorage.getItem('user')) {
        const user = JSON.parse(localStorage.getItem('user')!);
        user.avatar = avatar;
        localStorage.setItem('user', JSON.stringify(user));
      }
      return {
        ...state,
        user: {
          ...state.user,
          avatar: avatar,
        },
      };
    }
    default:
      return state;
  }
};
