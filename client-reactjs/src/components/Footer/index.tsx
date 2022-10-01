import React from 'react';
import CodepenButton from '../Socials/Codepen';
import GitHubSocials from '../Socials/GitHub';
import '../../styles/footer.css';
// import RssSocials from "../Socials/test_Rss";

const Footer = () => {
  return (
    <footer className='footer'>
      <p>Copyright &copy; 2022 Skyface753</p>
      <GitHubSocials href='https://github.com/skyface753'></GitHubSocials>
      {/* <RssSocials /> */}
      <CodepenButton href='https://codepen.io/skyface753' />
      <p
        style={{
          margin: '3px',
        }}
      >
        <a
          href='/impressum'
          style={{
            marginRight: '10px',
          }}
        >
          Impressum
        </a>
        <a href='/privacy-policy'>Datenschutz</a>
      </p>
    </footer>
  );
};

export default Footer;
