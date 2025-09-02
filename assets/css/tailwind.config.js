/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    // scan Phoenix templates and source files for classes
    "../**/*.{ex,heex,leex,html,js,ts,jsx,tsx,css}",
    // also scan assets files
    "./**/*.{js,ts,jsx,tsx,css,html}"
  ],
  safelist: ["prose-overlay"],
  theme: {
    extend: {
      typography: {
        DEFAULT: {
          css: {
            h1: { fontFamily: 'Montserrat, sans-serif', fontWeight: '900' },
            h2: { fontFamily: 'Montserrat, sans-serif', fontWeight: '900' },
            h3: { fontFamily: 'Montserrat, sans-serif', fontWeight: '700' },
            h4: { fontFamily: 'Montserrat, sans-serif', fontWeight: '700' },
            h5: { fontFamily: 'Montserrat, sans-serif' },
            h6: { fontFamily: 'Montserrat, sans-serif' },
          },
        },
        // custom overlay theme for message overlay markdown
        overlay: {
          css: {
            h1: {
              fontFamily: 'Montserrat, sans-serif',
              fontWeight: '700',
              fontSize: '1.875rem', // lg/display sized for overlay H1
              color: 'oklch(37.2% 0.044 257.287)'//slate-700
            },
            h2: {
              fontFamily: 'Montserrat, sans-serif',
              fontWeight: '700',
              fontSize: '1rem', // base
              color: 'oklch(37.2% 0.044 257.287)'
            },
            h3: {
              fontFamily: 'Montserrat, sans-serif',
              fontWeight: '700',
              fontSize: '0.875rem', // sm
              color: 'oklch(37.2% 0.044 257.287)'
            },
            h4: {
              fontFamily: 'Montserrat, sans-serif',
              fontWeight: '700',
              fontSize: '0.75rem', // xs
              color: 'oklch(37.2% 0.044 257.287)'
            },
            p: {
              fontFamily: 'Montserrat, sans-serif',
              color: 'oklch(37.2% 0.044 257.287)'//slate-700
            },
            strong: {
              fontFamily: 'Montserrat, sans-serif',
              color: 'oklch(37.2% 0.044 257.287)'//slate-700
            },
            li: {
              fontFamily: 'Montserrat, sans-serif',
              color: 'oklch(37.2% 0.044 257.287)'//slate-700
            },
          }
        }
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};
