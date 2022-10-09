import mysql, { ResultSetHeader } from 'mysql2/promise';
import config from '../config.json';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function query(sql: string, params: any[]) {
  try {
    if (process.env.SQLDEBUG == 'true') {
      console.log('SQL Query: ' + sql);
      console.log('SQL Params: ' + JSON.stringify(params));
      console.log('DB CONFIG: ' + JSON.stringify(config.SQLDB));
    }
    const connection = await mysql.createConnection(config.SQLDB);
    const [results] = await connection.execute(sql, params);
    connection.end();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return results as any;
  } catch (error) {
    console.log('SQL ERROR: ' + error);
    return false;
  }
}

export default {
  query,
};

// module.exports = {
//   query,
// };
initDb();
async function initDb() {
  // Create Tables
  const role =
    'CREATE TABLE IF NOT EXISTS `role` ( `id` int(11) NOT NULL AUTO_INCREMENT, `title` varchar(50) NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4';
  const user =
    'CREATE TABLE IF NOT EXISTS `user` (`id` int(11) NOT NULL AUTO_INCREMENT,`username` varchar(100) NOT NULL, `email` varchar(100) NOT NULL,`password` varchar(250) NOT NULL,`roleFk` int(11) NOT NULL DEFAULT 1, PRIMARY KEY (`id`), KEY `role_fk` (`roleFk`), CONSTRAINT `role_fk` FOREIGN KEY (`roleFk`) REFERENCES `role` (`id`) ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4';
  const user_2fa =
    'CREATE TABLE IF NOT EXISTS `user_2fa` ( `userFk` int(11) NOT NULL, `secretBase32` varchar(250) NOT NULL, `verified` tinyint(1) NOT NULL DEFAULT 0, PRIMARY KEY (`userFk`), CONSTRAINT `user2fa_userFK` FOREIGN KEY (`userFk`) REFERENCES `user` (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
  const reals =
    'CREATE TABLE IF NOT EXISTS `reals` (`id` INT NOT NULL AUTO_INCREMENT , `userFk` INT NOT NULL , `frontPath` VARCHAR(250) NOT NULL, `backPath` VARCHAR(250) NOT NULL , `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `timespan` BIGINT(20) NOT NULL , PRIMARY KEY (`id`), CONSTRAINT `reals_user` FOREIGN KEY (`userFk`) REFERENCES `user`(`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
  const friendships =
    'create table if not exists `friendship` (user int(11), friend int(11),primary key(user, friend), `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, key(friend, user), constraint `fk_user` foreign key (user) references user(id),constraint `fk_friend` foreign key (friend) references user(id));';
  const roleResult = (await query(role, [])) as ResultSetHeader;
  const userResult = (await query(user, [])) as ResultSetHeader;
  const user2faResult = (await query(user_2fa, [])) as ResultSetHeader;
  const realsResult = (await query(reals, [])) as ResultSetHeader;
  const friendshipsResult = (await query(friendships, [])) as ResultSetHeader;
  if (process.env.SQLDEBUG == 'true') {
    console.log('Role Result: ' + JSON.stringify(roleResult));
    console.log('User Result: ' + JSON.stringify(userResult));
    console.log('User 2FA Result: ' + JSON.stringify(user2faResult));
    console.log('Reals Result: ' + JSON.stringify(realsResult));
    console.log('Friendships Result: ' + JSON.stringify(friendshipsResult));
  }
  if (
    roleResult &&
    roleResult.warningStatus == 1 &&
    userResult &&
    userResult.warningStatus == 1 &&
    user2faResult &&
    user2faResult.warningStatus == 1 &&
    realsResult &&
    realsResult.warningStatus == 1 &&
    friendshipsResult &&
    friendshipsResult.warningStatus == 1
  ) {
    console.log('SQL Tables already exist - no need to create');
    return;
  }
  console.log('Creating SQL Tables');
  const commands: string[] = [];

  commands.push('ALTER TABLE `user` ADD UNIQUE KEY `email` (`email`)');
  commands.push('ALTER TABLE `user` ADD UNIQUE KEY `username` (`username`)');
  commands.push("INSERT INTO `role` (`id`, `title`) VALUES (1, 'user')");
  commands.push("INSERT INTO `role` (`id`, `title`) VALUES (2, 'admin')");
  commands.push(
    "INSERT INTO `user` (`id`, `username`, `email`, `password`, `roleFk`) VALUES (1, 'skyface', 'admin@example.de', '$2b$10$957SjQ2vLy8aBPIOn6aKduL/tMjzvKGSGK8N34idvLaf/PTjXG0ve', 2)"
  );
  commands.push(
    "INSERT INTO `user` (`id`, `username`, `email`, `password`, `roleFk`) VALUES (2, 'justANormalUser', 'test@example.de', '$2b$10$RZLpZn3IdVHfxn40HZdd8uZTjeRCgxkG2ZGTdzhqsTG6t/dK/BR7.', 1)"
  );
  // commands.push(
  //   'ALTER TABLE `user_2fa` ADD CONSTRAINT `user2fa_userFK` FOREIGN KEY (`userFk`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;'
  // );
  const promises = [];
  for (let i = 0; i < commands.length; i++) {
    promises.push(
      new Promise((resolve) => {
        query(commands[i], []).then((result) => {
          if (process.env.SQLDEBUG == 'true') {
            console.log('SQL Result: ' + JSON.stringify(result));
          }
          resolve(result);
        });
      })
    );
  }
  Promise.all(promises).then(() => {
    console.log('SQL Tables created');
  });
}

import bycrypt from 'bcrypt';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function create1000TestUser() {
  for (let i = 0; i < 1000; i++) {
    const username = randomUsernameGenerator();
    const email = username + '@example.de';
    const password = 'test';
    const hashedPassword = await bycrypt.hash(password, config.BCRYPT_ROUNDS);
    const role = 1;
    const user = await query(
      'INSERT INTO `user` (`username`, `email`, `password`, `roleFk`) VALUES (?, ?, ?, ?)',
      [username, email, hashedPassword, role]
    );
    console.log(user);
  }
}

// create1000TestUser();

function randomUsernameGenerator() {
  let username = '';
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  const length = 10;
  for (let i = 0; i < length; i++) {
    username += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return username;
}
