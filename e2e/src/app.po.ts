import { browser, by, element } from 'protractor';

export class AppPage {

  navigateToLogin() {
    return browser.get('/login');
  }

  getLoginTitle() {
    return element(by.css('mat-card-title:not(.logo-name)')).getText();
  }

  getEmailInput() {
    return element(by.css('input[name="email"]'));
  }

  getPasswordInput() {
    return element(by.css('input[name="password"]'));
  }

  getLoginButton() {
    return element(by.css('button[type="submit"]'));
  }
}