import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { purgeCss } from 'vite-plugin-tailwind-purgecss';
import { generateRobotsTxtSitemap } from './src/tools/plugins/robots_txt_sitemap';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

export default defineConfig({
  plugins: [
    sveltekit(),
    purgeCss(),
    generateRobotsTxtSitemap(),
    SvelteKitPWA({
      srcDir: './src',
      mode: 'production',
      strategies: 'generateSW',
      registerType: 'autoUpdate',
      injectRegister: 'auto',
      devOptions: {
        enabled: true,
        type: 'module'
      },
      manifest: {
        name: 'SvaraDarshini',
        short_name: 'SvaraDarshini',
        description: 'Your app description',
        theme_color: '#181e20',
        background_color: '#333',
        display: 'standalone',
        start_url: '/',
        scope: '/',
        icons: [
          {
            src: 'img/icon_128.png',
            sizes: '128x128',
            type: 'image/png'
          },
          {
            src: 'img/icon_512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,webp,jpg,jpeg}'],
        cleanupOutdatedCaches: true,
        sourcemap: false
      }
    })
  ],
  worker: {
    format: 'es'
  }
});
