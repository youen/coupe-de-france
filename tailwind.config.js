/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{elm,js,json}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#ea3a60',
        secondary: '#2d3436',
      },
      fontFamily: {
        sans: ['Poppins', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
