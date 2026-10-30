import {createRequire} from 'node:module';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {chromium}=require('D:/LLM-Data/npm-cache/_npx/9833c18b2d85bc59/node_modules/playwright/index.js');
const {expect}=require('D:/LLM-Data/npm-cache/_npx/9833c18b2d85bc59/node_modules/playwright/test.js');
const root=resolve(import.meta.dirname,'../../..');
const out=resolve(root,'handoffs/2026-10-30/client-dry-run','browser-'+new Date().toISOString().replace(/[:.]/g,'-'));
await mkdir(out,{recursive:true});
const base=process.env.DEMO_TEST_URL??'http://127.0.0.1:8137';
const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
const context=await browser.newContext({viewport:{width:1440,height:1000}});
const page=await context.newPage();
const errors=[],external=[],cases=[];
page.on('pageerror',e=>errors.push(e.message));
await context.route('**/*',route=>{
  const url=new URL(route.request().url());
  if(['http:','https:'].includes(url.protocol)&&url.origin!==new URL(base).origin){external.push(url.href);return route.abort();}
  return route.continue();
});
async function semantics(tab){
  const button=tab.getByRole('button',{name:'Enable accessibility'});
  if(await button.count())await button.dispatchEvent('click');
}
async function check(name,fn){console.log('CHECK '+name);await fn();cases.push({name,status:'PASS'});}
async function fill(label,value){const field=page.getByRole('textbox',{name:label,exact:true});await field.click();await expect(field).toBeFocused();await field.press('ControlOrMeta+A',{delay:100});await field.pressSequentially(value,{delay:80});await expect(field).toHaveValue(value);await field.press('Tab');}
async function waitText(text){await page.getByText(text,{exact:true}).first().waitFor();}
async function openStaff(pin='2468'){
  await page.getByRole('button',{name:'Open staff receiving',exact:true}).click();
  await fill('Staff PIN',pin);
  await page.getByRole('button',{name:'Verify and unlock',exact:true}).click();
  await page.getByRole('textbox',{name:'Item name',exact:true}).waitFor();
}
async function back(){await page.getByRole('button',{name:'Back to demo',exact:true}).click();await page.getByRole('button',{name:'Open admin setup',exact:true}).waitFor();}
try{
  await page.goto(base);
  await semantics(page);
  await page.getByRole('button',{name:'Open admin setup',exact:true}).waitFor();
  await check('Welcome page and isolated browser storage',async()=>{
    assert.match(await page.locator('body').ariaSnapshot(),/CLIENT DRY RUN/);
    await page.screenshot({path:resolve(out,'welcome-desktop.png')});
  });
  await page.getByRole('button',{name:'Open admin setup',exact:true}).click();
  await page.getByText('Store & branch',{exact:true}).waitFor();
  await page.screenshot({path:resolve(out,'admin-desktop.png')});
  await check('Admin edits, saves and activates practice setup',async()=>{
    await fill('Store name','Client Practice Grocer');
    await page.getByRole('button',{name:'Save draft',exact:true}).click();
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('shelflife.client-dry-run.v1')).draft.configuration.store.display_name==='Client Practice Grocer');
    console.log('saved setup');
    await page.getByRole('button',{name:'6. Review & activate',exact:true}).click();
    await page.getByRole('button',{name:'Review activation',exact:true}).click();
    await fill('Change reason','Client dry run');
    await page.getByRole('button',{name:'Activate configuration',exact:true}).click();
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('shelflife.client-dry-run.v1')).active_revision===1);
    console.log('activated setup');
    await back();
    await page.reload();await semantics(page);
    await page.getByRole('button',{name:'Open admin setup',exact:true}).click();
    await page.getByRole('textbox',{name:'Store name',exact:true}).waitFor();
    await page.getByRole('textbox',{name:'Store name',exact:true}).click();
    assert.equal(await page.getByRole('textbox',{name:'Store name',exact:true}).inputValue(),'Client Practice Grocer');
    await back();
  });
  await check('Invalid PIN is rejected and staff can look up and save a draft',async()=>{
    await page.getByRole('button',{name:'Open staff receiving',exact:true}).click();
    await fill('Staff PIN','0000');
    await page.getByRole('button',{name:'Verify and unlock',exact:true}).click();
    await waitText('Unable to verify. Check your PIN and connection.');
    await fill('Staff PIN','2468');
    await page.getByRole('button',{name:'Verify and unlock',exact:true}).click();
    await fill('Item name','milk');
    await page.getByRole('button',{name:'Look up item by name',exact:true}).click();
    await page.getByRole('button',{name:'Whole milk · 0990000000011',exact:true}).click();
    await fill('Quantity as entered','6');
    await fill('Notes','Fictional delivery DRY-001. Printed expiry 2030-01-15.');
    await page.getByRole('button',{name:'Save on this device',exact:true}).click();
    await waitText('Saved on this device');
    assert.match(await page.locator('body').ariaSnapshot(),/Client Practice Grocer/);
    await page.screenshot({path:resolve(out,'staff-desktop.png')});
  });
  await check('Saved staff draft survives page reload and PIN re-entry',async()=>{
    await page.reload();await semantics(page);await openStaff();
    await page.getByRole('button',{name:'Open a saved draft',exact:true}).click();
    await page.getByRole('menuitem',{name:'Whole milk',exact:true}).click();
    for(const [label,value] of [['Item name','Whole milk'],['Quantity as entered','6'],['Notes','Fictional delivery DRY-001. Printed expiry 2030-01-15.']]){
      const field=page.getByRole('textbox',{name:label,exact:true});await field.click();await expect(field).toHaveValue(value);
    }
    await page.screenshot({path:resolve(out,'staff-reopened.png')});
  });
  await check('Switching practice staff conceals Alex drafts and restores them for Alex',async()=>{
    await page.getByRole('button',{name:'Lock',exact:true}).click();
    await fill('Staff PIN','1357');await page.getByRole('button',{name:'Verify and unlock',exact:true}).click();
    await waitText('New draft · not saved');
    assert.match(await page.locator('body').ariaSnapshot(),/Sam · practice staff/);
    assert.equal(await page.getByRole('button',{name:'Open a saved draft',exact:true}).count(),0);
    await page.getByRole('button',{name:'Lock',exact:true}).click();
    await fill('Staff PIN','2468');await page.getByRole('button',{name:'Verify and unlock',exact:true}).click();
    await page.getByRole('button',{name:'Open a saved draft',exact:true}).waitFor();await back();
  });
  await check('Second tab is blocked from changing the same practice data',async()=>{
    const second=await context.newPage();await second.goto(base);await semantics(second);
    await second.getByText(/This practice store is already open in another tab/).waitFor();
    assert.equal(await second.getByRole('button',{name:'Open admin setup',exact:true}).count(),0);await second.close();await page.bringToFront();
  });
  await check('Reset cancellation preserves data; confirmed reset clears only demo data',async()=>{
    await page.evaluate(()=>localStorage.setItem('unrelated-test-sentinel','preserve'));
    await page.getByRole('button',{name:'Reset practice data',exact:true}).click();
    await page.getByRole('button',{name:'Keep my practice data',exact:true}).click();
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('shelflife.client-dry-run.v1')).active_revision),1);
    await page.getByRole('button',{name:'Reset practice data',exact:true}).click();
    await page.getByRole('button',{name:'Reset this browser',exact:true}).click();
    await page.getByText('0 saved practice drafts',{exact:true}).waitFor();
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('shelflife.client-dry-run.v1')).active_revision),0);
    assert.equal(await page.evaluate(()=>localStorage.getItem('unrelated-test-sentinel')),'preserve');
    await openStaff();await waitText('New draft · not saved');
    assert.equal(await page.getByRole('button',{name:'Open a saved draft',exact:true}).count(),0);await back();
  });
  await check('Mobile viewport supports welcome, admin and staff in an independent browser',async()=>{
    const mobile=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
    const tab=await mobile.newPage();tab.on('pageerror',e=>errors.push(e.message));
    await mobile.route('**/*',route=>{const u=new URL(route.request().url());if(['http:','https:'].includes(u.protocol)&&u.origin!==new URL(base).origin){external.push(u.href);return route.abort();}return route.continue();});
    await tab.goto(base);await semantics(tab);await tab.getByRole('button',{name:'Open admin setup',exact:true}).waitFor();
    assert.equal(await tab.evaluate(()=>localStorage.getItem('unrelated-test-sentinel')),null);
    await tab.screenshot({path:resolve(out,'welcome-mobile.png')});
    await tab.getByRole('button',{name:'Open admin setup',exact:true}).click();await tab.getByRole('textbox',{name:'Store name',exact:true}).waitFor();
    await tab.screenshot({path:resolve(out,'admin-mobile.png')});
    await tab.getByRole('button',{name:'Back to demo',exact:true}).click();
    await tab.getByRole('button',{name:'Open staff receiving',exact:true}).click();
    const pin=tab.getByRole('textbox',{name:'Staff PIN',exact:true});await pin.click();await pin.pressSequentially('2468',{delay:50});await pin.press('Tab');
    await tab.getByRole('button',{name:'Verify and unlock',exact:true}).click();await tab.getByRole('textbox',{name:'Item name',exact:true}).waitFor();
    await tab.screenshot({path:resolve(out,'staff-mobile.png')});await mobile.close();
  });
  console.log('OUTPUT '+out);
  assert.equal(errors.length,0,errors.join('\n'));assert.equal(external.length,0,external.join('\n'));
}catch(error){
  console.log('FAIL STACK '+error.stack);
  console.log('STATE '+await page.evaluate(()=>{const s=JSON.parse(localStorage.getItem('shelflife.client-dry-run.v1')||'null');return JSON.stringify({draft:s?.draft?.configuration?.store,activeRevision:s?.active_revision});}).catch(()=>null));
  cases.push({name:'browser execution',status:'FAIL',error:String(error)});
  await page.screenshot({path:resolve(out,'browser-failure.png')}).catch(()=>{});
  console.log((await page.locator('body').ariaSnapshot()).slice(0,14000));
  process.exitCode=1;
}finally{
  await writeFile(resolve(out,'BROWSER_TEST.json'),JSON.stringify({time:new Date().toISOString(),url:base,cases,errors,external},null,2));
  console.log(JSON.stringify({cases,errors,external}));
  await browser.close();
}

