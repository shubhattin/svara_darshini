import type { Plugin } from 'vite';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

/**
 * Generates a minimal manifest.webmanifest file for Android builds
 * where PWA functionality is disabled
 */
export function generateAndroidManifest(): Plugin {
  return {
    name: 'generate-android-manifest',
    closeBundle() {
      const manifest = {
        name: 'Svara Darshini',
        short_name: 'Svara Darshini',
        display: 'standalone'
      };

      // Write to both client output and build directory
      const outputPaths = [
        '.svelte-kit/output/client/manifest.webmanifest',
        'build/manifest.webmanifest'
      ];

      outputPaths.forEach((path) => {
        try {
          const dir = path.substring(0, path.lastIndexOf('/'));
          mkdirSync(dir, { recursive: true });
          writeFileSync(path, JSON.stringify(manifest, null, 2));
          console.log(`✓ Generated minimal manifest at ${path}`);
        } catch (error) {
          console.error(`Failed to write manifest to ${path}:`, error);
        }
      });
    }
  };
}
