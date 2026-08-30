#include <stdint.h>
#import <Foundation/Foundation.h>
#import <objc/message.h>
@protocol BetterPlayerCallback;
@protocol BetterPlayerLogCallback;

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

typedef struct {
  int64_t version;
  void* (*newWaiter)(void);
  void (*awaitWaiter)(void*);
  void* (*currentIsolate)(void);
  void (*enterIsolate)(void*);
  void (*exitIsolate)(void);
  int64_t (*getMainPortId)(void);
  bool (*getCurrentThreadOwnsIsolate)(int64_t);
  void (*invokeListenerPortBlock)(int64_t port, void*);
  void (*invokeBlockingPortBlock)(int64_t port, void*, void*);
} DOBJC_Context;

id objc_retainBlock(id);

#define BLOCKING_BLOCK_IMPL(ctx, TYPE, SIG, INVOKE_DIRECT, INVOKE_LISTENER)    \
  assert(ctx->version >= 1);                                                   \
  void* targetIsolate = ctx->currentIsolate();                                 \
  int64_t targetPort = ctx->getMainPortId == NULL ? 0 : ctx->getMainPortId();  \
  __block __weak TYPE weakSelfBlock = nil;                                     \
  TYPE strongSelfBlock = [SIG {                                                \
    void* currentIsolate = ctx->currentIsolate();                              \
    bool mayEnterIsolate =                                                     \
        currentIsolate == NULL &&                                              \
        ctx->getCurrentThreadOwnsIsolate != NULL &&                            \
        ctx->getCurrentThreadOwnsIsolate(targetPort);                          \
    if (currentIsolate == targetIsolate || mayEnterIsolate) {                  \
      if (mayEnterIsolate) {                                                   \
        ctx->enterIsolate(targetIsolate);                                      \
      }                                                                        \
      INVOKE_DIRECT;                                                           \
      if (mayEnterIsolate) {                                                   \
        ctx->exitIsolate();                                                    \
      }                                                                        \
    } else {                                                                   \
      void* waiter = ctx->newWaiter();                                         \
      TYPE selfRetain = [weakSelfBlock copy];                                  \
      INVOKE_LISTENER;                                                         \
      ctx->awaitWaiter(waiter);                                                \
      (void)selfRetain;                                                        \
    }                                                                          \
  } copy];                                                                     \
  weakSelfBlock = strongSelfBlock;                                             \
  return strongSelfBlock;


__attribute__((visibility("default"))) __attribute__((used))
Protocol* _x224me_BetterPlayerCallback(void) { return @protocol(BetterPlayerCallback); }

__attribute__((visibility("default"))) __attribute__((used))
Protocol* _x224me_BetterPlayerLogCallback(void) { return @protocol(BetterPlayerLogCallback); }

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_1s56lr9 : NSObject
@property (copy) id block;
@property BOOL arg0;
@end
@implementation _x224me_BlockArgs_1s56lr9
@end

typedef void  (^_ListenerTrampoline)(BOOL arg0);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline _x224me_wrapListenerBlock_1s56lr9(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline weakSelfBlock = nil;
  _ListenerTrampoline strongSelfBlock = [^void(BOOL arg0) {
    @autoreleasepool {
      _x224me_BlockArgs_1s56lr9* args = [[_x224me_BlockArgs_1s56lr9 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline)(void * waiter, BOOL arg0);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline _x224me_wrapBlockingBlock_1s56lr9(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline, ^void(BOOL arg0), {
    @autoreleasepool {
      _x224me_BlockArgs_1s56lr9* args = [[_x224me_BlockArgs_1s56lr9 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_1s56lr9* args = [[_x224me_BlockArgs_1s56lr9 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_ovsamd : NSObject
@property (copy) id block;
@property void * arg0;
@end
@implementation _x224me_BlockArgs_ovsamd
@end

typedef void  (^_ListenerTrampoline_1)(void * arg0);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_1 _x224me_wrapListenerBlock_ovsamd(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_1 weakSelfBlock = nil;
  _ListenerTrampoline_1 strongSelfBlock = [^void(void * arg0) {
    @autoreleasepool {
      _x224me_BlockArgs_ovsamd* args = [[_x224me_BlockArgs_ovsamd alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_1)(void * waiter, void * arg0);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_1 _x224me_wrapBlockingBlock_ovsamd(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_1, ^void(void * arg0), {
    @autoreleasepool {
      _x224me_BlockArgs_ovsamd* args = [[_x224me_BlockArgs_ovsamd alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_ovsamd* args = [[_x224me_BlockArgs_ovsamd alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline)(void * sel);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_ovsamd(id target, void * sel) {
  return ((_ProtocolTrampoline)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_ak6mql : NSObject
@property (copy) id block;
@property void * arg0;
@property int64_t arg1;
@property (strong) id arg2;
@end
@implementation _x224me_BlockArgs_ak6mql
@end

typedef void  (^_ListenerTrampoline_2)(void * arg0, int64_t arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_2 _x224me_wrapListenerBlock_ak6mql(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_2 weakSelfBlock = nil;
  _ListenerTrampoline_2 strongSelfBlock = [^void(void * arg0, int64_t arg1, id arg2) {
    @autoreleasepool {
      _x224me_BlockArgs_ak6mql* args = [[_x224me_BlockArgs_ak6mql alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_2)(void * waiter, void * arg0, int64_t arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_2 _x224me_wrapBlockingBlock_ak6mql(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_2, ^void(void * arg0, int64_t arg1, id arg2), {
    @autoreleasepool {
      _x224me_BlockArgs_ak6mql* args = [[_x224me_BlockArgs_ak6mql alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_ak6mql* args = [[_x224me_BlockArgs_ak6mql alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_1)(void * sel, int64_t arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_ak6mql(id target, void * sel, int64_t arg1, id arg2) {
  return ((_ProtocolTrampoline_1)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_1ancy3p : NSObject
@property (copy) id block;
@property void * arg0;
@property int64_t arg1;
@property double arg2;
@property double arg3;
@property (strong) id arg4;
@end
@implementation _x224me_BlockArgs_1ancy3p
@end

typedef void  (^_ListenerTrampoline_3)(void * arg0, int64_t arg1, double arg2, double arg3, id arg4);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_3 _x224me_wrapListenerBlock_1ancy3p(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_3 weakSelfBlock = nil;
  _ListenerTrampoline_3 strongSelfBlock = [^void(void * arg0, int64_t arg1, double arg2, double arg3, id arg4) {
    @autoreleasepool {
      _x224me_BlockArgs_1ancy3p* args = [[_x224me_BlockArgs_1ancy3p alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      args.arg4 = arg4;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_3)(void * waiter, void * arg0, int64_t arg1, double arg2, double arg3, id arg4);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_3 _x224me_wrapBlockingBlock_1ancy3p(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_3, ^void(void * arg0, int64_t arg1, double arg2, double arg3, id arg4), {
    @autoreleasepool {
      _x224me_BlockArgs_1ancy3p* args = [[_x224me_BlockArgs_1ancy3p alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      args.arg4 = arg4;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_1ancy3p* args = [[_x224me_BlockArgs_1ancy3p alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      args.arg4 = arg4;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_2)(void * sel, int64_t arg1, double arg2, double arg3, id arg4);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_1ancy3p(id target, void * sel, int64_t arg1, double arg2, double arg3, id arg4) {
  return ((_ProtocolTrampoline_2)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2, arg3, arg4);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_1ihjjaj : NSObject
@property (copy) id block;
@property void * arg0;
@property long arg1;
@property (strong) id arg2;
@property (strong) id arg3;
@end
@implementation _x224me_BlockArgs_1ihjjaj
@end

typedef void  (^_ListenerTrampoline_4)(void * arg0, long arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_4 _x224me_wrapListenerBlock_1ihjjaj(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_4 weakSelfBlock = nil;
  _ListenerTrampoline_4 strongSelfBlock = [^void(void * arg0, long arg1, id arg2, id arg3) {
    @autoreleasepool {
      _x224me_BlockArgs_1ihjjaj* args = [[_x224me_BlockArgs_1ihjjaj alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_4)(void * waiter, void * arg0, long arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_4 _x224me_wrapBlockingBlock_1ihjjaj(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_4, ^void(void * arg0, long arg1, id arg2, id arg3), {
    @autoreleasepool {
      _x224me_BlockArgs_1ihjjaj* args = [[_x224me_BlockArgs_1ihjjaj alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_1ihjjaj* args = [[_x224me_BlockArgs_1ihjjaj alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_3)(void * sel, long arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_1ihjjaj(id target, void * sel, long arg1, id arg2, id arg3) {
  return ((_ProtocolTrampoline_3)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2, arg3);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_18v1jvf : NSObject
@property (copy) id block;
@property void * arg0;
@property (strong) id arg1;
@end
@implementation _x224me_BlockArgs_18v1jvf
@end

typedef void  (^_ListenerTrampoline_5)(void * arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_5 _x224me_wrapListenerBlock_18v1jvf(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_5 weakSelfBlock = nil;
  _ListenerTrampoline_5 strongSelfBlock = [^void(void * arg0, id arg1) {
    @autoreleasepool {
      _x224me_BlockArgs_18v1jvf* args = [[_x224me_BlockArgs_18v1jvf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_5)(void * waiter, void * arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_5 _x224me_wrapBlockingBlock_18v1jvf(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_5, ^void(void * arg0, id arg1), {
    @autoreleasepool {
      _x224me_BlockArgs_18v1jvf* args = [[_x224me_BlockArgs_18v1jvf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_18v1jvf* args = [[_x224me_BlockArgs_18v1jvf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_4)(void * sel, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_18v1jvf(id target, void * sel, id arg1) {
  return ((_ProtocolTrampoline_4)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_fjrv01 : NSObject
@property (copy) id block;
@property void * arg0;
@property (strong) id arg1;
@property (strong) id arg2;
@end
@implementation _x224me_BlockArgs_fjrv01
@end

typedef void  (^_ListenerTrampoline_6)(void * arg0, id arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_6 _x224me_wrapListenerBlock_fjrv01(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_6 weakSelfBlock = nil;
  _ListenerTrampoline_6 strongSelfBlock = [^void(void * arg0, id arg1, id arg2) {
    @autoreleasepool {
      _x224me_BlockArgs_fjrv01* args = [[_x224me_BlockArgs_fjrv01 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_6)(void * waiter, void * arg0, id arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_6 _x224me_wrapBlockingBlock_fjrv01(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_6, ^void(void * arg0, id arg1, id arg2), {
    @autoreleasepool {
      _x224me_BlockArgs_fjrv01* args = [[_x224me_BlockArgs_fjrv01 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_fjrv01* args = [[_x224me_BlockArgs_fjrv01 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_5)(void * sel, id arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_fjrv01(id target, void * sel, id arg1, id arg2) {
  return ((_ProtocolTrampoline_5)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2);
}

__attribute__((visibility("default")))
@interface _x224me_BlockArgs_1tz5yf : NSObject
@property (copy) id block;
@property void * arg0;
@property (strong) id arg1;
@property (strong) id arg2;
@property (strong) id arg3;
@end
@implementation _x224me_BlockArgs_1tz5yf
@end

typedef void  (^_ListenerTrampoline_7)(void * arg0, id arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_7 _x224me_wrapListenerBlock_1tz5yf(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_7 weakSelfBlock = nil;
  _ListenerTrampoline_7 strongSelfBlock = [^void(void * arg0, id arg1, id arg2, id arg3) {
    @autoreleasepool {
      _x224me_BlockArgs_1tz5yf* args = [[_x224me_BlockArgs_1tz5yf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_7)(void * waiter, void * arg0, id arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_7 _x224me_wrapBlockingBlock_1tz5yf(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_7, ^void(void * arg0, id arg1, id arg2, id arg3), {
    @autoreleasepool {
      _x224me_BlockArgs_1tz5yf* args = [[_x224me_BlockArgs_1tz5yf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _x224me_BlockArgs_1tz5yf* args = [[_x224me_BlockArgs_1tz5yf alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_6)(void * sel, id arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
void  _x224me_protocolTrampoline_1tz5yf(id target, void * sel, id arg1, id arg2, id arg3) {
  return ((_ProtocolTrampoline_6)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2, arg3);
}
#undef BLOCKING_BLOCK_IMPL

#pragma clang diagnostic pop
