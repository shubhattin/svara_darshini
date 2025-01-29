import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { purgeCss } from 'vite-plugin-tailwind-purgecss';
import { generateRobotsTxt } from './src/tools/plugins/robots_txt';

export default defineConfig({
  plugins: [sveltekit(), purgeCss(), generateRobotsTxt()],
  worker: {
    format: 'es'
  }
});
