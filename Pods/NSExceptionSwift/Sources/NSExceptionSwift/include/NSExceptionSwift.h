#if __APPLE__

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void handlingNSException(void(NS_NOESCAPE ^ block)(void), NSException * _Nullable __autoreleasing * _Nonnull exception) NS_REFINED_FOR_SWIFT;

NS_ASSUME_NONNULL_END

#endif
