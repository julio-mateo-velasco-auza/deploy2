/** @type {import('tailwind.css').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,ts,tsx,md,mdx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:'#eef6ff',100:'#d8e9ff',200:'#b1d2ff',300:'#85b8fb',400:'#5a96e6',
          500:'#3e7dd2',600:'#2f65b0',700:'#285392',800:'#234876',900:'#213e63'
        }
      }
    }
  },
  plugins: [],
}
