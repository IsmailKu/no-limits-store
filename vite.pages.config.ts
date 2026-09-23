import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/postcss';
import {defineConfig} from 'vite';
import {resolve} from 'node:path';

export default defineConfig({
  root:resolve(__dirname,'pages'),
  publicDir:resolve(__dirname,'public'),
  base:'/no-limits-store/',
  css:{postcss:{plugins:[tailwindcss()]}},
  plugins:[react()],
  build:{outDir:resolve(__dirname,'dist-pages'),emptyOutDir:true},
});
