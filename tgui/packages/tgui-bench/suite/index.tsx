/**
 * @file
 * @copyright 2021 Aleksej Komarov
 * @license MIT
 */

import { setupGlobalEvents } from 'tgui/events';
import 'tgui/styles/main.scss';
import { Benchmark } from './lib';

const sendMessage = (obj: any) => {
  const req = new XMLHttpRequest();
  req.open('POST', `/message`, false);
  req.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
  req.timeout = 250;
  req.send(JSON.stringify(obj));
};

const setupApp = async () => {
  // Delay setup
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupApp);
    return;
  }

  setupGlobalEvents({
    ignoreWindowFocus: true,
  });

  const requireTest = require.context('.', false, /\.test\./);

  for (const file of requireTest.keys()) {
    sendMessage({ type: 'suite-start', file });
    try {
      const tests = requireTest(file);
      await new Promise<void>((resolve) => {
        const suite = new Benchmark.Suite(file, {
          onCycle(e) {
            sendMessage({
              type: 'suite-cycle',
              message: String(e.target),
            });
          },
          onComplete() {
            sendMessage({
              type: 'suite-complete',
              message: 'Fastest is ' + this.filter('fastest').map('name'),
            });
            resolve();
          },
        });
        for (const [name, fn] of Object.entries(tests)) {
          if (typeof fn === 'function') {
            suite.add(name, fn);
          }
        }
        suite.run();
      });
    }
    catch (error) {
      sendMessage({ type: 'error', error });
    }
  }
  sendMessage({ type: 'finished' });
};

setupApp();
