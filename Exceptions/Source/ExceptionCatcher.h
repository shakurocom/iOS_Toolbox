//
//
//

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable public tryBlock(void(^_Nonnull block)(void)) {
    @try {
        block();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
