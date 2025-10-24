// astro.config.mjs
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import compress from 'astro-compress';

export default defineConfig({
  output: 'static',
  base: '/inbolsaNeo/', // Mantener igual
  server: { port: 4321, host: true },
  build: {
    format: 'file',
    inlineStylesheets: 'auto',
    assets: '_assets',
  },
  integrations: [
    tailwind({
      applyBaseStyles: true,
    }),
    compress(),
  ],
  vite: {
    server: {
      // Proxy para XAMPP
      proxy: {
        '/api': 'http://localhost/inbolsaNeo/inbolsa-api/api',
      },
    },
    build: {
      target: ['es2020', 'edge88', 'firefox79', 'chrome87', 'safari14'],
      cssMinify: true,
      // Importante: Incluir los directorios y archivos que necesitas
      outDir: 'dist',
      rollupOptions: {
        input: {
          main: 'src/pages/**/*.astro',
          lib: 'src/lib/**/*.ts', // Incluir los archivos de lib
        },
      },
    },
  },
})