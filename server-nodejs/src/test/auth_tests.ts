import chai from 'chai';
import chaiHttp from 'chai-http';
import { describe } from 'mocha';
import { expect } from 'chai';
import server from '../index';
import db from '../services/db';
import totp from 'totp-generator';
chai.use(chaiHttp);
import credentials from './credentials.json';

describe('Login', () => {
  describe('/POST login-user-success', () => {
    it('it should login a user', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send(credentials.user)
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.user.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(1);
          expect(res.body.success).to.be.true;
          done();
        });
    });
    it('it should login a admin', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.admin.email.toUpperCase(), // test case insensitivity
          password: credentials.admin.password,
        })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.admin.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(2);
          expect(res.body.success).to.be.true;
          done();
        });
    });
  });
  describe('/POST login-user-fail', () => {
    it('it should not login a user - wrong mail', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: 'wrong' + credentials.user.email,
          password: credentials.user.password,
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
    it('it should not login a user - wrong password', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.user.email,
          password: credentials.user.password + 'wrong',
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
  });
});

describe('Refresh', () => {
  describe('/POST refresh-token-success', () => {
    let refreshToken: string;
    before((done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send(credentials.user)
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          refreshToken = res.body.data.refreshToken;
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.user.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(1);
          expect(res.body.success).to.be.true;
          done();
        });
    });
    it('it should refresh a token', (done) => {
      chai
        .request(server)
        .post('/api/auth/refreshToken')
        .set('content-type', 'application/json')
        .send({ refreshToken: refreshToken })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          expect(res.body.data.refreshToken).to.not.equal(refreshToken);
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.user.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(1);
          expect(res.body.success).to.be.true;
          done();
        });
    });
  });
  describe('/POST refresh-token-fail', () => {
    it('it should not refresh a token - wrong token', (done) => {
      chai
        .request(server)
        .post('/api/auth/refreshToken')
        .set('content-type', 'application/json')
        .send({ refreshToken: 'wrong' })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
  });
});

describe('Logout', () => {
  describe('/POST logout-success', () => {
    let refreshToken: string;
    before((done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send(credentials.user)
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          refreshToken = res.body.data.refreshToken;
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.user.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(1);
          expect(res.body.success).to.be.true;
          done();
        });
    });
    it('it should logout a user', (done) => {
      chai
        .request(server)
        .post('/api/auth/logout')
        .set('content-type', 'application/json')
        .send({ refreshToken: refreshToken })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.be.equal('Logged out');
          expect(res.body.success).to.be.true;
          done();
        });
    });
  });
  describe('/POST logout-fail', () => {
    it('it should not logout a user - wrong token', (done) => {
      chai
        .request(server)
        .post('/api/auth/logout')
        .set('content-type', 'application/json')
        .send({ refreshToken: 'wrong' })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
  });
  describe('/POST logout-fail', () => {
    it('it should not logout a user - no token', (done) => {
      chai
        .request(server)
        .post('/api/auth/logout')
        .set('content-type', 'application/json')
        .send()
        .end((err, res) => {
          expect(res).to.have.status(401);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal(
            'Access Denied - Not Authorized'
          );

          done();
        });
    });
  });
});

describe('Register', () => {
  describe('/POST register-success', () => {
    it('it should register a user', (done) => {
      chai
        .request(server)
        .put('/api/auth/register')
        .set('content-type', 'application/json')
        .send({
          email: credentials.newUser.email,
          password: credentials.newUser.password,
          username: credentials.newUser.username,
        })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          expect(res.body.data).to.have.property('csrfToken');
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.equal(credentials.newUser.email);
          expect(res.body.data.user).to.have.property('roleFk');
          expect(res.body.data.user.roleFk).to.equal(1);
          expect(res.body.success).to.be.true;
          done();
        });
    });
  });
  describe('/POST register-fail', () => {
    afterEach(async () => {
      await db.query('DELETE FROM user WHERE email = ?', [
        credentials.newUser.email,
      ]);
    });
    it('it should not register a user - email already exists', (done) => {
      chai
        .request(server)
        .put('/api/auth/register')
        .set('content-type', 'application/json')
        .send({
          email: credentials.newUser.email.toUpperCase(),
          password: credentials.newUser.password,
          username: credentials.newUser.username,
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
    it('it should not register a user - unsecure password', (done) => {
      chai
        .request(server)
        .put('/api/auth/register')
        .set('content-type', 'application/json')
        .send({
          email: credentials.newUser.email,
          username: credentials.newUser.username,
          password: credentials.newUser.passwordNotSecure,
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');

          done();
        });
    });
    it('it should not register a user - missing email', (done) => {
      chai
        .request(server)
        .put('/api/auth/register')
        .set('content-type', 'application/json')
        .send({
          username: credentials.newUser.username,
          password: credentials.newUser.password,
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Missing Parameters');

          done();
        });
    });
    credentials.newUser.invalidMail.forEach((mail) => {
      it(`it should not register a user - invalid email ${mail}`, (done) => {
        chai
          .request(server)
          .put('/api/auth/register')
          .set('content-type', 'application/json')
          .send({
            email: mail,
            username: credentials.newUser.username,
            password: credentials.newUser.password,
          })
          .end((err, res) => {
            expect(res).to.have.status(400);
            expect(res.body).to.have.property('success');
            expect(res.body.success).to.be.false;
            expect(res.body).to.have.property('message');
            expect(res.body.message).to.be.equal('Error');

            done();
          });
      });
    });
    credentials.newUser.invalidUsername.forEach((username) => {
      it(`it should not register a user - invalid username ${username}`, (done) => {
        chai
          .request(server)
          .put('/api/auth/register')
          .set('content-type', 'application/json')
          .send({
            email: credentials.newUser.email,
            username,
            password: credentials.newUser.password,
          })
          .end((err, res) => {
            expect(res).to.have.status(400);
            expect(res.body).to.have.property('success');
            expect(res.body.success).to.be.false;
            expect(res.body).to.have.property('message');
            expect(res.body.message).to.be.equal('Error');

            done();
          });
      });
      credentials.newUser.invalidPassword.forEach((password) => {
        it(`it should not register a user - unsecure password ${password}`, (done) => {
          chai
            .request(server)
            .put('/api/auth/register')
            .set('content-type', 'application/json')
            .send({
              email: credentials.newUser.email,
              username: credentials.newUser.username,
              password,
            })
            .end((err, res) => {
              expect(res).to.have.status(400);
              expect(res.body).to.have.property('success');
              expect(res.body.success).to.be.false;
              expect(res.body).to.have.property('message');
              expect(res.body.message).to.be.equal('Error');

              done();
            });
        });
      });
    });
  });
});

describe('2FA', () => {
  describe('/POST 2fa-success', () => {
    let csrfToken: string;
    let cookie: string;
    before(async () => {
      // Login user
      const res = await chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.user.email,
          password: credentials.user.password,
        });
      csrfToken = res.body.data.csrfToken;
      cookie = res.header['set-cookie'];
    });
    let secretBase32: string;
    it('it should enable 2fa', (done) => {
      chai
        .request(server)
        .post('/api/auth/2fa/enable')
        .set('content-type', 'application/json')
        .set('X-CSRF-Token', csrfToken)
        .set('Cookie', cookie)
        .send({
          password: credentials.user.password,
        })

        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.true;
          expect(res.body.data).to.have.property('secretBase32');
          secretBase32 = res.body.data.secretBase32;
          done();
        });
    });
    it('it should verify 2fa', (done) => {
      const currentCode = totp(secretBase32);
      chai
        .request(server)
        .post('/api/auth/2fa/verify')
        .set('content-type', 'application/json')
        .set('X-CSRF-Token', csrfToken)
        .set('Cookie', cookie)
        .send({
          currentCode: currentCode,
        })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.true;
          done();
        });
    });
    it('it should not login user - no totpCode provided', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.user.email,
          password: credentials.user.password,
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('2FA required');
          done();
        });
    });
    it('it should not login user - wrong totpCode provided', (done) => {
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.user.email,
          password: credentials.user.password,
          totpCode: '123456',
        })
        .end((err, res) => {
          expect(res).to.have.status(400);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.false;
          expect(res.body).to.have.property('message');
          expect(res.body.message).to.be.equal('Error');
          done();
        });
    });
    it('it should login user', (done) => {
      const currentCode = totp(secretBase32);
      chai
        .request(server)
        .post('/api/auth/login')
        .set('content-type', 'application/json')
        .send({
          email: credentials.user.email,
          password: credentials.user.password,
          totpCode: currentCode,
        })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.true;
          expect(res.body.data).to.have.property('user');
          expect(res.body.data.user).to.have.property('email');
          expect(res.body.data.user.email).to.be.equal(credentials.user.email);
          expect(res.body.data).to.have.property('accessToken');
          expect(res.body.data).to.have.property('refreshToken');
          expect(res.body.data.user).to.have.property('id');
          expect(res.body.data).to.have.property('csrfToken');
          done();
        });
    });
    it('it should disable 2fa', (done) => {
      const password = credentials.user.password;
      const totpCode = totp(secretBase32);
      chai
        .request(server)
        .post('/api/auth/2fa/disable')
        .set('content-type', 'application/json')
        .set('X-CSRF-Token', csrfToken)
        .set('Cookie', cookie)
        .send({
          password: password,
          totpCode: totpCode,
        })
        .end((err, res) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property('success');
          expect(res.body.success).to.be.true;
          done();
        });
    });
  });
});
