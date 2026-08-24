/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Better Player',
  tagline: 'Advanced video player for Flutter',
  favicon: 'img/logo.png',

  url: 'https://jhomlala.github.io',
  baseUrl: '/betterplayer/',

  organizationName: 'jhomlala',
  projectName: 'betterplayer',

  onBrokenLinks: 'ignore',
  onBrokenMarkdownLinks: 'ignore',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/',
          path: '.',
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/jhomlala/betterplayer/tree/master/',
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: false,
        respectPrefersColorScheme: false,
      },
      metadata: [
        {name: 'keywords', content: 'flutter, video player, flutter video player, streaming, hls, dash, drm, chewie, better player'},
        {name: 'description', content: 'Advanced video player for Flutter with support for HLS, DASH, DRM, caching, subtitles, custom controls, and more.'},
      ],
      image: 'https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/1.png',
      navbar: {
        title: 'Better Player',
        logo: {
          alt: 'Better Player Logo',
          src: 'img/logo.png',
        },
        items: [
          {
            to: '/',
            label: 'Docs',
            position: 'left',
          },
          {
            href: 'https://pub.dev/packages/better_player',
            label: 'pub.dev',
            position: 'right',
          },
          {
            href: 'https://github.com/jhomlala/betterplayer',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        copyright: `Copyright © ${new Date().getFullYear()} Better Player. Built with Docusaurus.`,
      },
      prism: {
        additionalLanguages: ['dart', 'yaml'],
      },
    }),
};

module.exports = config;
