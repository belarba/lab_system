import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    watch: {
      usePolling: true,
      interval: 1000,
    },
    hmr: {
      port: 5173,
      host: '0.0.0.0'
    },
  },
  // Cache em diretório com permissões
  cacheDir: '/tmp/.vite',
  optimizeDeps: {
    exclude: ['fsevents'],
    force: true, // Força rebuild das dependências
  },
  esbuild: {
    target: 'esnext'
  }
})
