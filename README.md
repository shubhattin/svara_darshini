# 🎵 Svara Darshini

**An intuitive tool to visualize, learn and understand the pitches of Indian Classical and Western Music**

Svara Darshini is a web-based pitch detection and visualization tool that bridges the gap between Western and Indian Classical music systems. Using real-time microphone input, it provides an elegant circular display that shows both Western note names and Indian Classical Sargam notations simultaneously.

## ✨ Features

### 🎯 Core Functionality

- **Real-time Pitch Detection**: Accurate frequency detection using advanced audio processing
- **Dual Music System Support**: Simultaneous display of Western notes and Indian Classical Sargam
- **Visual Tuning Aid**: Color-coded needle showing pitch accuracy (green = in tune, red = out of tune)
- **Cents Deviation**: Precise tuning information with cent-level accuracy
- **Frequency Display**: Real-time frequency readings in Hz
- **Offline Access**: Works without internet connection once loaded

### 🎨 Beautiful Visualization

- **Circular Interface**: Elegant SVG-based circular display with concentric rings
- **Dual Notation Rings**:
  - Outer ring: Indian Sargam (स, र, ग, म, प, ध, न)
  - Inner ring: Western notes (C, D, E, F, G, A, B)
- **Dynamic Needle**: Smooth animations showing pitch deviation
- **Clarity Meter**: Visual feedback on signal strength and clarity
- **Responsive Design**: Optimized for both desktop and mobile devices

### ⚙️ Customization Options

- **Configurable Sa Position**: Set any Western note as the base "Sa" for Indian Classical music
- **Multiple Orientations**: Choose between radial and vertical text orientations for both Sargam and Western notes
- **Device Selection**: Support for multiple microphone inputs with device switching
- **Theme Options**: Dark and light theme support
- **Settings Persistence**: All preferences automatically saved

### 📱 Modern Web App Features

- **Progressive Web App (PWA)**: Install on your device for offline access
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile
- **Auto-Sleep**: Automatically stops after 30 minutes of inactivity to conserve resources
- **Service Worker**: Background updates and caching for better performance

## 🚀 Technology Stack

- **Frontend**: Svelte 5 + SvelteKit
- **Language**: TypeScript
- **Styling**: TailwindCSS + SkeletonLabs UI
- **Audio Processing**: Web Audio API + Pitchy library
- **Build Tool**: Vite
- **Deployment**: Netlify
- **PWA**: Vite PWA Plugin with Workbox
