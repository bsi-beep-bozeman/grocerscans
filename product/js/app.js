import { supa, currentProfile } from './supa.js';
import { renderLogin } from './screens/login.js';
import { renderShell } from './screens/shell.js';

const root = document.getElementById('root');

async function route() {
  const session = await currentProfile();
  if (!session) {
    renderLogin(root, route);
    return;
  }
  await renderShell(root, session, route);
}

supa.auth.onAuthStateChange(() => route());
route();
