/** @type {import('tailwindcss').Config} */
module.exports = {
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
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
};
