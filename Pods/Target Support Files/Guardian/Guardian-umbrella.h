#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "A0HMAC.h"
#import "A0RSA.h"
#import "A0SHA.h"
#import "Guardian.h"

FOUNDATION_EXPORT double GuardianVersionNumber;
FOUNDATION_EXPORT const unsigned char GuardianVersionString[];

