import React from 'react';
import PropTypes from 'prop-types';
import '../../styles/socials.css';

type Props = {
  href: string;
  size?: number;
};
export default class GitHubSocials extends React.Component<Props> {
  render() {
    if (
      window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    ) {
      return (
        <a href={this.props.href} target='_blank' rel='noopener noreferrer'>
          <img
            src={require('../../img/GitHub-PNG/GitHub-Mark-Light-120px-plus.png')}
            className='socials-icon'
            alt='GitHub-Icon'
          />
        </a>
      );
    }
    return (
      <a href={this.props.href} target='_blank' rel='noopener noreferrer'>
        <img
          src={require('../../img/GitHub-PNG/GitHub-Mark-120px-plus.png')}
          className='socials-icon'
          alt='GitHub-Icon'
        />
      </a>
    );
  }

  static get propTypes() {
    return {
      link: PropTypes.string,
    };
  }

  static get defaultProps() {
    return {
      link: '#',
    };
  }
}
