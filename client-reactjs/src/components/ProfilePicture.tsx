import React from 'react';
import config from '../config.json';
import defaultImage from '../img/default-profile-pic.png';

interface Props {
  avatarPath: string | undefined;
}

export default class ProfilePictureComponent extends React.Component<Props> {
  render() {
    return (
      <>
        <img
          className='profile-pic'
          src={
            this.props.avatarPath
              ? config.BackendFilesUrl + this.props.avatarPath
              : defaultImage
          }
          alt='User'
        />
      </>
    );
  }
}
