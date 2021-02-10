import 'package:flutter/cupertino.dart';
import 'util.dart';

class MimeTypes {
  static const String BASE_TYPE_VIDEO = 'video';
  static const String BASE_TYPE_AUDIO = 'audio';
  static const String BASE_TYPE_TEXT = 'text';
  static const String BASE_TYPE_APPLICATION = 'application';
  static const String VIDEO_MP4 = '$BASE_TYPE_VIDEO/mp4';
  static const String VIDEO_WEBM = '$BASE_TYPE_VIDEO/webm';
  static const String VIDEO_H263 = '$BASE_TYPE_VIDEO/3gpp';
  static const String VIDEO_H264 = '$BASE_TYPE_VIDEO/avc';
  static const String VIDEO_H265 = '$BASE_TYPE_VIDEO/hevc';
  static const String VIDEO_VP8 = '$BASE_TYPE_VIDEO/x-vnd.on2.vp8';
  static const String VIDEO_VP9 = '$BASE_TYPE_VIDEO/x-vnd.on2.vp9';
  static const String VIDEO_AV1 = '$BASE_TYPE_VIDEO/av01';
  static const String VIDEO_MP4V = '$BASE_TYPE_VIDEO/mp4v-es';
  static const String VIDEO_MPEG = '$BASE_TYPE_VIDEO/mpeg';
  static const String VIDEO_MPEG2 = '$BASE_TYPE_VIDEO/mpeg2';
  static const String VIDEO_VC1 = '$BASE_TYPE_VIDEO/wvc1';
  static const String VIDEO_DIVX = '$BASE_TYPE_VIDEO/divx';
  static const String VIDEO_DOLBY_VISION = '$BASE_TYPE_VIDEO/dolby-vision';
  static const String VIDEO_UNKNOWN = '$BASE_TYPE_VIDEO/x-unknown';
  static const String AUDIO_MP4 = '$BASE_TYPE_AUDIO/mp4';
  static const String AUDIO_AAC = '$BASE_TYPE_AUDIO/mp4a-latm';
  static const String AUDIO_WEBM = '$BASE_TYPE_AUDIO/webm';
  static const String AUDIO_MPEG = '$BASE_TYPE_AUDIO/mpeg';
  static const String AUDIO_MPEG_L1 = '$BASE_TYPE_AUDIO/mpeg-L1';
  static const String AUDIO_MPEG_L2 = '$BASE_TYPE_AUDIO/mpeg-L2';
  static const String AUDIO_RAW = '$BASE_TYPE_AUDIO/raw';
  static const String AUDIO_ALAW = '$BASE_TYPE_AUDIO/g711-alaw';
  static const String AUDIO_MLAW = '$BASE_TYPE_AUDIO/g711-mlaw';
  static const String AUDIO_AC3 = '$BASE_TYPE_AUDIO/ac3';
  static const String AUDIO_E_AC3 = '$BASE_TYPE_AUDIO/eac3';
  static const String AUDIO_E_AC3_JOC = '$BASE_TYPE_AUDIO/eac3-joc';
  static const String AUDIO_AC4 = '$BASE_TYPE_AUDIO/ac4';
  static const String AUDIO_TRUEHD = '$BASE_TYPE_AUDIO/true-hd';
  static const String AUDIO_DTS = '$BASE_TYPE_AUDIO/vnd.dts';
  static const String AUDIO_DTS_HD = '$BASE_TYPE_AUDIO/vnd.dts.hd';
  static const String AUDIO_DTS_EXPRESS =
      '$BASE_TYPE_AUDIO/vnd.dts.hd;profile=lbr';
  static const String AUDIO_VORBIS = '$BASE_TYPE_AUDIO/vorbis';
  static const String AUDIO_OPUS = '$BASE_TYPE_AUDIO/opus';
  static const String AUDIO_AMR_NB = '$BASE_TYPE_AUDIO/3gpp';
  static const String AUDIO_AMR_WB = '$BASE_TYPE_AUDIO/amr-wb';
  static const String AUDIO_FLAC = '$BASE_TYPE_AUDIO/flac';
  static const String AUDIO_ALAC = '$BASE_TYPE_AUDIO/alac';
  static const String AUDIO_MSGSM = '$BASE_TYPE_AUDIO/gsm';
  static const String AUDIO_UNKNOWN = '$BASE_TYPE_AUDIO/x-unknown';
  static const String TEXT_VTT = '$BASE_TYPE_TEXT/vtt';
  static const String TEXT_SSA = '$BASE_TYPE_TEXT/x-ssa';
  static const String APPLICATION_MP4 = '$BASE_TYPE_APPLICATION/mp4';
  static const String APPLICATION_WEBM = '$BASE_TYPE_APPLICATION/webm';
  static const String APPLICATION_MPD = '$BASE_TYPE_APPLICATION/dash+xml';
  static const String APPLICATION_M3U8 = '$BASE_TYPE_APPLICATION/x-mpegURL';
  static const String APPLICATION_SS = '$BASE_TYPE_APPLICATION/vnd.ms-sstr+xml';
  static const String APPLICATION_ID3 = '$BASE_TYPE_APPLICATION/id3';
  static const String APPLICATION_CEA608 = '$BASE_TYPE_APPLICATION/cea-608';
  static const String APPLICATION_CEA708 = '$BASE_TYPE_APPLICATION/cea-708';
  static const String APPLICATION_SUBRIP = '$BASE_TYPE_APPLICATION/x-subrip';
  static const String APPLICATION_TTML = '$BASE_TYPE_APPLICATION/ttml+xml';
  static const String APPLICATION_TX3G =
      '$BASE_TYPE_APPLICATION/x-quicktime-tx3g';
  static const String APPLICATION_MP4VTT = '$BASE_TYPE_APPLICATION/x-mp4-vtt';
  static const String APPLICATION_MP4CEA608 =
      '$BASE_TYPE_APPLICATION/x-mp4-cea-608';
  static const String APPLICATION_RAWCC = '$BASE_TYPE_APPLICATION/x-rawcc';
  static const String APPLICATION_VOBSUB = '$BASE_TYPE_APPLICATION/vobsub';
  static const String APPLICATION_PGS = '$BASE_TYPE_APPLICATION/pgs';
  static const String APPLICATION_SCTE35 = '$BASE_TYPE_APPLICATION/x-scte35';
  static const String APPLICATION_CAMERA_MOTION =
      '$BASE_TYPE_APPLICATION/x-camera-motion';
  static const String APPLICATION_EMSG = '$BASE_TYPE_APPLICATION/x-emsg';
  static const String APPLICATION_DVBSUBS = '$BASE_TYPE_APPLICATION/dvbsubs';
  static const String APPLICATION_EXIF = '$BASE_TYPE_APPLICATION/x-exif';
  static const String APPLICATION_ICY = '$BASE_TYPE_APPLICATION/x-icy';

  static const String HLS = 'hls';

  static final List<CustomMimeType> _customMimeTypes = [];

  static String _getMimeTypeFromMp4ObjectType(int objectType) {
    switch (objectType) {
      case 0x20:
        return MimeTypes.VIDEO_MP4V;
      case 0x21:
        return MimeTypes.VIDEO_H264;
      case 0x23:
        return MimeTypes.VIDEO_H265;
      case 0x60:
      case 0x61:
      case 0x62:
      case 0x63:
      case 0x64:
      case 0x65:
        return MimeTypes.VIDEO_MPEG2;
      case 0x6A:
        return MimeTypes.VIDEO_MPEG;
      case 0x69:
      case 0x6B:
        return MimeTypes.AUDIO_MPEG;
      case 0xA3:
        return MimeTypes.VIDEO_VC1;
      case 0xB1:
        return MimeTypes.VIDEO_VP9;
      case 0x40:
      case 0x66:
      case 0x67:
      case 0x68:
        return MimeTypes.AUDIO_AAC;
      case 0xA5:
        return MimeTypes.AUDIO_AC3;
      case 0xA6:
        return MimeTypes.AUDIO_E_AC3;
      case 0xA9:
      case 0xAC:
        return MimeTypes.AUDIO_DTS;
      case 0xAA:
      case 0xAB:
        return MimeTypes.AUDIO_DTS_HD;
      case 0xAD:
        return MimeTypes.AUDIO_OPUS;
      case 0xAE:
        return MimeTypes.AUDIO_AC4;
      default:
        return null;
    }
  }

  static String getMediaMimeType(String codec) {
    if (codec == null) return null;

    codec = codec.trim().toLowerCase();
    if (codec.startsWith('avc1') || codec.startsWith('avc3'))
      return MimeTypes.VIDEO_H264;

    if (codec.startsWith('hev1') || codec.startsWith('hvc1'))
      return MimeTypes.VIDEO_H265;

    if (codec.startsWith('dvav') ||
        codec.startsWith('dva1') ||
        codec.startsWith('dvhe') ||
        codec.startsWith('dvh1')) return MimeTypes.VIDEO_DOLBY_VISION;

    if (codec.startsWith('av01')) return MimeTypes.VIDEO_AV1;

    if (codec.startsWith('vp9') || codec.startsWith('vp09'))
      return MimeTypes.VIDEO_VP9;
    if (codec.startsWith('vp8') || codec.startsWith('vp08'))
      return MimeTypes.VIDEO_VP8;
    if (codec.startsWith('mp4a')) {
      String mimeType;
      if (codec.startsWith('mp4a.')) {
        String objectTypeString = codec.substring(5);
        if (objectTypeString.length >= 2) {
          try {
            String objectTypeHexString =
                objectTypeString.substring(0, 2).toUpperCase();
            int objectTypeInt = int.parse(objectTypeHexString, radix: 16);
            mimeType = _getMimeTypeFromMp4ObjectType(objectTypeInt);
          } on FormatException catch (ignored) {
            //do nothing
            print(ignored);
          }
        }
      }
      return mimeType ??= MimeTypes.AUDIO_AAC;
    }
    if (codec.startsWith('ac-3') || codec.startsWith('dac3'))
      return MimeTypes.AUDIO_AC3;

    if (codec.startsWith('ec-3') || codec.startsWith('dec3'))
      return MimeTypes.AUDIO_E_AC3;

    if (codec.startsWith('ec+3')) return MimeTypes.AUDIO_E_AC3_JOC;

    if (codec.startsWith('ac-4') || codec.startsWith('dac4'))
      return MimeTypes.AUDIO_AC4;

    if (codec.startsWith('dtsc') || codec.startsWith('dtse'))
      return MimeTypes.AUDIO_DTS;

    if (codec.startsWith('dtsh') || codec.startsWith('dtsl'))
      return MimeTypes.AUDIO_DTS_HD;
    if (codec.startsWith('opus')) return MimeTypes.AUDIO_OPUS;
    if (codec.startsWith('vorbis')) return MimeTypes.AUDIO_VORBIS;
    if (codec.startsWith('flac')) return MimeTypes.AUDIO_FLAC;
    return getCustomMimeTypeForCodec(codec);
  }

  static String getCustomMimeTypeForCodec(String codec) {
    for (final customMimeType in _customMimeTypes)
      if (codec.startsWith(customMimeType.codecPrefix))
        return customMimeType.mimeType;

    return null;
  }

  static int getTrackType(String mimeType) {
    if (mimeType?.isNotEmpty == false) return Util.TRACK_TYPE_UNKNOWN;

    if (isAudio(mimeType)) return Util.TRACK_TYPE_AUDIO;
    if (isVideo(mimeType)) return Util.TRACK_TYPE_VIDEO;
    if (isText(mimeType) ||
        APPLICATION_CEA608 == mimeType ||
        APPLICATION_CEA708 == mimeType ||
        APPLICATION_MP4CEA608 == mimeType ||
        APPLICATION_SUBRIP == mimeType ||
        APPLICATION_TTML == mimeType ||
        APPLICATION_TX3G == mimeType ||
        APPLICATION_MP4VTT == mimeType ||
        APPLICATION_RAWCC == mimeType ||
        APPLICATION_VOBSUB == mimeType ||
        APPLICATION_PGS == mimeType ||
        APPLICATION_DVBSUBS == mimeType)
      return Util.TRACK_TYPE_TEXT;
    else if ((APPLICATION_ID3 == mimeType) ||
        (APPLICATION_EMSG == mimeType) ||
        (APPLICATION_SCTE35 == mimeType))
      return Util.TRACK_TYPE_METADATA;
    else if (APPLICATION_CAMERA_MOTION == mimeType)
      return Util.TRACK_TYPE_CAMERA_MOTION;
    else
      return getTrackTypeForCustomMimeType(mimeType);
  }

  static int getTrackTypeForCustomMimeType(String mimeType) {
    for (final it in _customMimeTypes)
      if (it.mimeType == mimeType) return it.trackType;

    return Util.TRACK_TYPE_UNKNOWN;
  }

  static String getTopLevelType(String mimeType) {
    if (mimeType == null) return null;
    int indexOfSlash = mimeType.indexOf('/');
    if (indexOfSlash == -1) return null;
    return mimeType.substring(0, indexOfSlash);
  }

  static bool isAudio(String mimeType) =>
      BASE_TYPE_AUDIO == getTopLevelType(mimeType);

  static bool isVideo(String mimeType) =>
      BASE_TYPE_VIDEO == getTopLevelType(mimeType);

  static bool isText(String mimeType) =>
      BASE_TYPE_TEXT == getTopLevelType(mimeType);

  static int getTrackTypeOfCodec(String codec) {
    return getTrackType(getMediaMimeType(codec));
  }
}

class CustomMimeType {
  CustomMimeType({
    @required this.mimeType,
    @required this.codecPrefix,
    @required this.trackType,
  });

  final String mimeType;
  final String codecPrefix;
  final int trackType;
}
