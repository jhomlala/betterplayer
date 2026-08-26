/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    {
      type: 'category',
      label: 'Introduction',
      items: [
        'home',
        'install',
        'general_player_usage',
        'playlist_player_usage',
        'list_player_usage',
      ],
    },
    {
      type: 'category',
      label: 'Migrations',
      items: [
        'migration_to_1.x.x',
        'migration_from_video_player',
        'migration_from_chewie',
      ],
    },
    {
      type: 'category',
      label: 'Customization',
      items: [
        'general_configuration',
        'data_source_configuration',
        'controls_configuration',
        'subtitles_configuration',
        'cache_configuration',
        'buffering_configuration',
        'notification_configuration',
        'picture_in_picture_configuration',
        'drm_configuration',
        'playlist_configuration',
        'translations_configuration',
      ],
    },
    {
      type: 'category',
      label: 'Advanced Features',
      items: [
        'events',
        'player_behavior_on_visibility_change',
        'resolutions_of_video',
        'custom_element_in_overflow_menu',
        'enable_disable_controls',
        'overridden_aspect_ratio',
        'overridden_fit',
        'overridden_duration',
        'mix_audio_with_others',
        'manual_dispose',
        'source_load',
        'multiple_gesture_detector',
      ],
    },
  ],
};

module.exports = sidebars;
