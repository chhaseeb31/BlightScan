// Read-only backup of the deployed rules using the Firebase CLI login.
const fs = require('fs');
const path = require('path');
const base = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const auth = require(path.join(base, 'auth'));
const rules = require(path.join(base, 'gcp/rules'));
(async () => {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI login required');
  auth.setActiveAccount({}, account);
  const releases = await rules.listAllReleases('blightscan-2026');
  const backup = [];
  for (const release of releases) {
    const files = await rules.getRulesetContent(release.rulesetName);
    backup.push({release, files});
  }
  fs.mkdirSync('build/rules-backup', {recursive: true});
  fs.writeFileSync('build/rules-backup/deployed.json', JSON.stringify(backup, null, 2));
  console.log(JSON.stringify(backup, null, 2));
})().catch(e => { console.error(e.message); process.exitCode = 1; });
