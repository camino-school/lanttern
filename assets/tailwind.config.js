// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        ltrn: {
          primary: colors.cyan["400"],
          secondary: colors.rose["500"],
          dark: colors.slate["700"],
          subtle: colors.slate["400"],
          light: colors.slate["300"],
          lighter: colors.slate["200"],
          lightest: colors.slate["100"],
          mesh: {
            primary: colors.cyan["200"],
            cyan: colors.cyan["50"],
            rose: colors.rose["100"],
            violet: colors.violet["200"],
            yellow: colors.yellow["100"],
            lime: colors.lime["100"],
          },
          ai: {
            dark: colors.pink["800"],
            accent: colors.pink["500"],
            lighter: colors.pink["200"],
            lightest: colors.pink["50"],
          },
          diff: {
            dark: colors.violet["800"],
            accent: colors.violet["600"],
            lighter: colors.violet["200"],
            lightest: colors.violet["50"],
          },
          student: {
            dark: colors.yellow["700"],
            accent: colors.yellow["400"],
            lighter: colors.yellow["200"],
            lightest: colors.yellow["50"],
          },
          staff: {
            dark: colors.lime["800"],
            accent: colors.lime["500"],
            lighter: colors.lime["200"],
            lightest: colors.lime["50"],
          },
          alert: {
            accent: colors.red["500"],
            lighter: colors.red["100"]
          },
          warning: {
            accent: colors.amber["500"],
            lighter: colors.amber["200"]
          },
          success: {
            accent: colors.teal["500"],
            lighter: colors.teal["100"]
          }
        },
      },
      fontFamily: {
        display: ["Montserrat", "sans-serif"],
        mono: ['"Source Code Pro"', ...defaultTheme.fontFamily.mono],
        sans: ['"Open Sans"', ...defaultTheme.fontFamily.sans],
      },
      aria: {
        current: 'current="true"'
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            h1: { fontFamily: 'Montserrat, sans-serif', fontWeight: '900' },
            h2: { fontFamily: 'Montserrat, sans-serif', fontWeight: '900' },
            h3: { fontFamily: 'Montserrat, sans-serif', fontWeight: '700' },
            h4: { fontFamily: 'Montserrat, sans-serif', fontWeight: '700' },
            h5: { fontFamily: 'Montserrat, sans-serif' },
            h6: { fontFamily: 'Montserrat, sans-serif' },
          }
        }
      })
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant(
        "group-phx-click-loading",
        ":merge(.group).phx-click-loading &",
      )
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant(
        "group-phx-submit-loading",
        ":merge(.group).phx-submit-loading &",
      )
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant(
        "peer-phx-change-loading",
        ":merge(.peer).phx-change-loading ~ &"
      )
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
