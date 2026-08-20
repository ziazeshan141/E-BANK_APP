# E-Bank Login E2E Test

```ts
import { AppPage } from './app.po';
import { browser, logging } from 'protractor';

describe('E-Bank Login', () => {
  let page: AppPage;

  beforeEach(() => {
    page = new AppPage();
  });

  it('should display the login page', async () => {
    await page.navigateToLogin();

    expect(await page.getLoginTitle()).toEqual('User Sign In');
    expect(await page.getEmailInput().isPresent()).toBe(true);
    expect(await page.getPasswordInput().isPresent()).toBe(true);
    expect(await page.getLoginButton().isPresent()).toBe(true);
  });

  afterEach(async () => {
    const logs = await browser.manage().logs().get(logging.Type.BROWSER);

    const severeLogs = logs.filter(
      log => log.level === logging.Level.SEVERE
    );

    expect(severeLogs).toEqual([]);
  });
});
```
