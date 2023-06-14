#if __APPLE__

#import "NSExceptionSwift.h"

void handlingNSException(void(NS_NOESCAPE ^ block)(void), NSException * _Nullable __autoreleasing * _Nonnull exception) {
    @try {
        block();
    }
    @catch (NSException *handledException) {
        *exception = handledException;
    }
}

#endif
