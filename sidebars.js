/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    {
      type: 'category',
      label: 'Introduction',
      items: [
        'home',
        'install',
        'migration_from_video_player',
        'migration_from_chewie',
        'generalplayerusage',
        'playlistplayerusage',
        'listplayerusage',
      ],
    },
    {
      type: 'category',
      label: 'Customization',
      items: [
        'generalconfiguration',
        'datasourceconfiguration',
        'controlsconfiguration',
        'subtitlesconfiguration',
        'cacheconfiguration',
        'bufferingconfiguration',
        'notificationconfiguration',
        'pictureinpictureconfiguration',
        'drmconfiguration',
        'playlistconfiguration',
        'translationsconfiguration',
      ],
    },
    {
      type: 'category',
      label: 'Advanced Features',
      items: [
        'events',
        'playerbehavioronvisibilitychange',
        'resolutionsofvideo',
        'customelementinoverflowmenu',
        'enabledisablecontrols',
        'overriddenaspectratio',
        'overriddenfit',
        'overriddenduration',
        'mixaudiowithothers',
        'manualdispose',
        'sourceload',
        'multiplegesturedetector',
      ],
    },
  ],
};

module.exports = sidebars;
