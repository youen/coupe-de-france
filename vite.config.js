import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

export default defineConfig({
    base: '/coupe-de-france/',
    plugins: [elmPlugin()]
})
