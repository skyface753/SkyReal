import chai from 'chai';
import { describe, it } from 'mocha';
const expect = chai.expect;
import {
	validateEmail,
	validatePassword,
	validateUsername,
} from '../helpers/validator';
const testData = {
	invalidMails: [
		'test',
		'test@',
		'test@test',
		'test@test.',
		'de',
		'.de',
		'test.de',
		'@test.de',
		'test@.de',
	],
	validMails: ['test@test.de', 'test123@test.de', 'test123-_99@test.de'],
	// Invalid Passwords - Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character
	invalidPasswords: [
		'tT1!', // Too short
		'testtest', // No uppercase
		'TESTTEST', // No lowercase
		'TESTTEST1', // No lowercase
		'testtest!', // No uppercase
		'testtest1', // No special character
		'TESTTEST!', // No lowercase
		'!!!!!!!!!', // No lowercase, no uppercase, no number
		'testtesttest', // No special character
		'TESTTESTTEST', // No special character
		'TESTTESTTEST1', // No special character
		'TESTTESTTEST', // No special character
	], // @$!%*?&
	validPasswords: [
		'tesT123@',
		'tesT123$',
		'tesT123!',
		'tesT123%',
		'tesT123*',
		'tesT123?',
		'tesT123&',
	],
	invalidUsernames: [
		// Only alphanumeric characters, underscore and hyphen no spaces (min 3, max 20)
		't',
		'te',
		'*test',
		'test*',
		'!test',
		'test!',
		'test test',
	],
	validUsernames: ['test', 'test123', 'test123-_99'],
};

describe('Validator', () => {
	describe('Email', () => {
		// Test Invalid Emails
		testData.invalidMails.forEach((mail) => {
			it(`should return false for invalid mail: ${mail}`, () => {
				const result = validateEmail(mail);
				expect(result).to.be.false;
			});
		});
		// Test Valid Emails
		testData.validMails.forEach((mail) => {
			it(`should return true for valid mail: ${mail}`, () => {
				const result = validateEmail(mail);
				expect(result).to.be.true;
			});
		});
	});
	describe('Password', () => {
		// Test Invalid Passwords
		testData.invalidPasswords.forEach((password) => {
			it(`should return false for invalid password: ${password}`, () => {
				const result = validatePassword(password);
				expect(result).to.be.false;
			});
		});
		// Test Valid Passwords
		testData.validPasswords.forEach((password) => {
			it(`should return true for valid password: ${password}`, () => {
				const result = validatePassword(password);
				expect(result).to.be.true;
			});
		});
	});
	describe('Username', () => {
		// Test Invalid Usernames
		testData.invalidUsernames.forEach((username) => {
			it(`should return false for invalid username: ${username}`, () => {
				const result = validateUsername(username);
				expect(result).to.be.false;
			});
		});
		// Test Valid Usernames
		testData.validUsernames.forEach((username) => {
			it(`should return true for valid username: ${username}`, () => {
				const result = validateUsername(username);
				expect(result).to.be.true;
			});
		});
	});
});
