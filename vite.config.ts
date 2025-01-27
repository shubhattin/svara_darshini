import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { purgeCss } from 'vite-plugin-tailwind-purgecss';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

export default defineConfig({
  plugins: [
    sveltekit(),
    purgeCss(),
    SvelteKitPWA({
      strategies: 'generateSW',
      registerType: 'autoUpdate',
      devOptions: {
        enabled: true
      },
      manifest: {
        name: 'SvaraDarshini',
        short_name: 'SvaraDarshini',
        start_url: '/',
        scope: './',
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
        ],
        theme_color: '#181e20',
        background_color: '#333',
        display: 'standalone'
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,webp,jpg,jpeg}']
      }
    })
  ],
  worker: {
    format: 'es'
  }
});
