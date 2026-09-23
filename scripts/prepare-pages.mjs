import {copyFile,writeFile} from 'node:fs/promises';
const output=new URL('../dist-pages/',import.meta.url);
await copyFile(new URL('index.html',output),new URL('404.html',output));
await writeFile(new URL('.nojekyll',output),'');
