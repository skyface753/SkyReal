export const validateEmail = (email: string) => {
  const regex =
    /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return regex.test(email);
};

export const validatePassword = (password: string) => {
  // Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character:
  const regex =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return regex.test(password);
};

export const validateUsername = (username: string) => {
  // Only alphanumeric characters, underscore and hyphen no spaces (min 3, max 20)
  const regex = /^[a-zA-Z0-9_-]{3,20}$/;
  return regex.test(username);
};

