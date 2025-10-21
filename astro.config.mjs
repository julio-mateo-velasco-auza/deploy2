// astro.config.mjs
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import compress from 'astro-compress';

export default defineConfig({
  output: 'static',
  base: process.env.ASTRO_BASE || '/', // ← ej. '/pruebadeploy/' o '/inbolsaNeo/'
  server: { port: 4321, host: true },
  build: {
    format: 'file',
    inlineStylesheets: 'auto',
    assets: '_assets', // opcional: nombres estables
  },
  integrations: [
    tailwind({
      applyBaseStyles: true,
    }),
    compress(),
  ],
  vite: {
    server: {
      // Útil sólo en local, si usas php-apache docker
      proxy: {
        '/api': 'http://localhost:8088',
      },
    },
    build: {
      target: ['es2020', 'edge88', 'firefox79', 'chrome87', 'safari14'],
      cssMinify: true,
    },
  },
});
