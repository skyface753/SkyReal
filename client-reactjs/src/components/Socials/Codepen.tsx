import { FaCodepen } from 'react-icons/fa';
import PropTypes from 'prop-types';

import React from 'react';

type Props = {
  href: string;
  size: number;
};

export default class CodepenButton extends React.Component<Props> {
  render() {
    let { href, size } = this.props;

    return (
      <a
        href={href}
        target='_blank'
        rel='noopener noreferrer'
        style={{ color: 'white', textDecoration: 'none', marginLeft: '10px' }}
      >
        <FaCodepen
          style={{
            fontSize: size,
          }}
        />
      </a>
    );
  }

  static get propTypes() {
    return {
      link: PropTypes.string,
      size: PropTypes.string || '2.4em',
    };
  }

  static get defaultProps() {
    return {
      link: '#',
      size: '2.4em',
    };
  }
}

// export default function CodepenButton({ link, size = '2.4em' }) {
//   return (
//     <a
//       href={link}
//       target='_blank'
//       rel='noopener noreferrer'
//       style={{ color: 'white', textDecoration: 'none', marginLeft: '10px' }}
//     >
//       <FaCodepen
//         style={{
//           fontSize: size,
//         }}
//       />
//     </a>
//   );
// }
