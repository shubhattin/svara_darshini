import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { purgeCss } from 'vite-plugin-tailwind-purgecss';
import { generateRobotsTxtSitemap } from './src/tools/plugins/robots_txt_sitemap';

export default defineConfig({
  plugins: [sveltekit(), purgeCss(), generateRobotsTxtSitemap()],
  worker: {
    format: 'es'
  }
});
