import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// mpv_format enum constants
abstract class MpvFormat {
  static const int none = 0;
  static const int string = 1;
  static const int osdString = 2;
  static const int flag = 3;
  static const int int64 = 4;
  static const int doubleFormat = 5;
  static const int node = 6;
  static const int nodeArray = 7;
  static const int nodeMap = 8;
  static const int byteArray = 9;
}

// mpv_event_id enum constants
abstract class MpvEventId {
  static const int none = 0;
  static const int shutdown = 1;
  static const int logMessage = 2;
  static const int getPropertyReply = 3;
  static const int setPropertyReply = 4;
  static const int commandReply = 5;
  static const int startFile = 6;
  static const int endFile = 7;
  static const int fileLoaded = 8;
  static const int idle = 11;
  static const int tick = 14;
  static const int videoReconfig = 17;
  static const int audioReconfig = 18;
  static const int seek = 20;
  static const int playbackRestart = 21;
  static const int propertyChange = 22;
}

// Native struct definitions
final class MpvHandle extends ffi.Opaque {}

final class MpvEvent extends ffi.Struct {
  @ffi.Int32()
  external int eventId;

  @ffi.Int32()
  external int error;

  @ffi.Uint64()
  external int replyUserdata;

  external ffi.Pointer<ffi.Void> data;
}

final class MpvEventProperty extends ffi.Struct {
  external ffi.Pointer<Utf8> name;

  @ffi.Int32()
  external int format;

  external ffi.Pointer<ffi.Void> data;
}

// C function typedefs
typedef MpvCreateC = ffi.Pointer<MpvHandle> Function();
typedef MpvCreateDart = ffi.Pointer<MpvHandle> Function();

typedef MpvInitializeC = ffi.Int32 Function(ffi.Pointer<MpvHandle> ctx);
typedef MpvInitializeDart = int Function(ffi.Pointer<MpvHandle> ctx);

typedef MpvDestroyC = ffi.Void Function(ffi.Pointer<MpvHandle> ctx);
typedef MpvDestroyDart = void Function(ffi.Pointer<MpvHandle> ctx);

typedef MpvCommandC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<ffi.Pointer<Utf8>> args,
    );
typedef MpvCommandDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<ffi.Pointer<Utf8>> args,
    );

typedef MpvCommandStringC =
    ffi.Int32 Function(ffi.Pointer<MpvHandle> ctx, ffi.Pointer<Utf8> args);
typedef MpvCommandStringDart =
    int Function(ffi.Pointer<MpvHandle> ctx, ffi.Pointer<Utf8> args);

typedef MpvSetPropertyC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Int32 format,
      ffi.Pointer<ffi.Void> data,
    );
typedef MpvSetPropertyDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      int format,
      ffi.Pointer<ffi.Void> data,
    );

typedef MpvSetPropertyStringC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Pointer<Utf8> data,
    );
typedef MpvSetPropertyStringDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Pointer<Utf8> data,
    );

typedef MpvGetPropertyC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Int32 format,
      ffi.Pointer<ffi.Void> data,
    );
typedef MpvGetPropertyDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      int format,
      ffi.Pointer<ffi.Void> data,
    );

typedef MpvGetPropertyStringC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
    );
typedef MpvGetPropertyStringDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
    );

typedef MpvFreeC = ffi.Void Function(ffi.Pointer<ffi.Void> data);
typedef MpvFreeDart = void Function(ffi.Pointer<ffi.Void> data);

typedef MpvSetOptionStringC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Pointer<Utf8> data,
    );
typedef MpvSetOptionStringDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Pointer<Utf8> name,
      ffi.Pointer<Utf8> data,
    );

typedef MpvObservePropertyC =
    ffi.Int32 Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Uint64 replyUserdata,
      ffi.Pointer<Utf8> name,
      ffi.Int32 format,
    );
typedef MpvObservePropertyDart =
    int Function(
      ffi.Pointer<MpvHandle> ctx,
      int replyUserdata,
      ffi.Pointer<Utf8> name,
      int format,
    );

typedef MpvWaitEventC =
    ffi.Pointer<MpvEvent> Function(
      ffi.Pointer<MpvHandle> ctx,
      ffi.Double timeout,
    );
typedef MpvWaitEventDart =
    ffi.Pointer<MpvEvent> Function(ffi.Pointer<MpvHandle> ctx, double timeout);

/// Dynamic library bindings to libmpv.
class MpvBindings {
  MpvBindings(ffi.DynamicLibrary lib)
    : mpvCreate = lib.lookupFunction<MpvCreateC, MpvCreateDart>('mpv_create'),
      mpvInitialize = lib.lookupFunction<MpvInitializeC, MpvInitializeDart>(
        'mpv_initialize',
      ),
      mpvDestroy = lib.lookupFunction<MpvDestroyC, MpvDestroyDart>(
        'mpv_destroy',
      ),
      mpvCommand = lib.lookupFunction<MpvCommandC, MpvCommandDart>(
        'mpv_command',
      ),
      mpvCommandString = lib
          .lookupFunction<MpvCommandStringC, MpvCommandStringDart>(
            'mpv_command_string',
          ),
      mpvSetProperty = lib.lookupFunction<MpvSetPropertyC, MpvSetPropertyDart>(
        'mpv_set_property',
      ),
      mpvSetPropertyString = lib
          .lookupFunction<MpvSetPropertyStringC, MpvSetPropertyStringDart>(
            'mpv_set_property_string',
          ),
      mpvGetProperty = lib.lookupFunction<MpvGetPropertyC, MpvGetPropertyDart>(
        'mpv_get_property',
      ),
      mpvGetPropertyString = lib
          .lookupFunction<MpvGetPropertyStringC, MpvGetPropertyStringDart>(
            'mpv_get_property_string',
          ),
      mpvFree = lib.lookupFunction<MpvFreeC, MpvFreeDart>('mpv_free'),
      mpvSetOptionString = lib
          .lookupFunction<MpvSetOptionStringC, MpvSetOptionStringDart>(
            'mpv_set_option_string',
          ),
      mpvObserveProperty = lib
          .lookupFunction<MpvObservePropertyC, MpvObservePropertyDart>(
            'mpv_observe_property',
          ),
      mpvWaitEvent = lib.lookupFunction<MpvWaitEventC, MpvWaitEventDart>(
        'mpv_wait_event',
      );

  final MpvCreateDart mpvCreate;
  final MpvInitializeDart mpvInitialize;
  final MpvDestroyDart mpvDestroy;
  final MpvCommandDart mpvCommand;
  final MpvCommandStringDart mpvCommandString;
  final MpvSetPropertyDart mpvSetProperty;
  final MpvSetPropertyStringDart mpvSetPropertyString;
  final MpvGetPropertyDart mpvGetProperty;
  final MpvGetPropertyStringDart mpvGetPropertyString;
  final MpvFreeDart mpvFree;
  final MpvSetOptionStringDart mpvSetOptionString;
  final MpvObservePropertyDart mpvObserveProperty;
  final MpvWaitEventDart mpvWaitEvent;

  static MpvBindings? _instance;

  static MpvBindings? get instance {
    if (_instance != null) return _instance;
    try {
      final lib = ffi.DynamicLibrary.open('mpv-2.dll');
      return _instance = MpvBindings(lib);
    } catch (_) {
      return null;
    }
  }

  static set instance(MpvBindings? value) {
    _instance = value;
  }
}
