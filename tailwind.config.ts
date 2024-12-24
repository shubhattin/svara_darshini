import type { Config } from 'tailwindcss';
import { skeleton, contentPath } from '@skeletonlabs/skeleton/plugin';
import * as themes from '@skeletonlabs/skeleton/themes';
import forms from '@tailwindcss/forms';

const config = {
  darkMode: 'selector',
  content: [
    './src/**/*.{html,js,svelte,ts}',
    contentPath(import.meta.url, 'svelte')
  ],
  theme: {
    extend: {}
  },
  plugins: [
    forms,
    skeleton({
      // NOTE: each theme included will be added to your CSS bundle
      themes: [ themes.wintry ]
  })
  ]
} satisfies Config;

export default config;
