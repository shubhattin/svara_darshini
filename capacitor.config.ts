import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.shubhattin.svara_darshini',
  appName: 'Svara Darshini',
  webDir: 'build',
  plugins: {
    StatusBar: {
      style: 'Dark',
      backgroundColor: '#1e293b',
      overlaysWebView: false
    }
  }
};

export default config;
