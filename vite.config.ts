import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { generateRobotsTxtSitemap } from './src/tools/plugins/robots_txt_sitemap';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';
import tailwindcss from '@tailwindcss/vite';
import devtoolsJson from 'vite-plugin-devtools-json';
import { generateAndroidManifest } from './src/tools/plugins/android_manifest';

const IS_ANDROID_BUILD = process.env.IS_ANDROID_BUILD === 'true';

export default defineConfig({
  plugins: [
    tailwindcss(),
    sveltekit(),
    devtoolsJson(),
    generateRobotsTxtSitemap(),
    ...(!IS_ANDROID_BUILD
      ? [
          SvelteKitPWA({
            strategies: 'generateSW',
            registerType: 'prompt',
            injectRegister: 'script',
            // ^ The option does not seem top work so we are adding it manually in +layout.svelte
            devOptions: {
              enabled: true,
              type: 'module'
            },
            workbox: {
              globPatterns: [
                '**/*.{js,css,html,ico,png,svg,webp,webmanifest,jpg,jpeg,ttf,woff2,otf}'
              ],
              cleanupOutdatedCaches: true,
              clientsClaim: true,
              skipWaiting: false
            },
            manifest: {
              name: 'Svara Darshini',
              short_name: 'Svara Darshini',
              description:
                'Svara Darshini is an intuitive tool to understand Principles of Music that are common across the world',
              theme_color: '#181e20',
              background_color: '#333',
              display: 'standalone',
              start_url: '/',
              scope: '/',
              id: '/?svara_darshini=1',
              display_override: ['standalone'],
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
            }
          })
        ]
      : [generateAndroidManifest()])
  ],
  resolve: {
    alias: IS_ANDROID_BUILD
      ? {
          'virtual:pwa-register/svelte': '/src/lib/pwa-stub.ts'
        }
      : {}
  },
  define: {
    'import.meta.env.IS_ANDROID_BUILD': JSON.stringify(String(IS_ANDROID_BUILD))
  }
});
