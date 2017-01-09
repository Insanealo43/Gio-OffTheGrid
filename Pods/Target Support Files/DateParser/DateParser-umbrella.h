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

#import "DateParser.h"
#import "NSDate+Parser.h"
#import "Tests-Bridging-Header.h"

FOUNDATION_EXPORT double DateParserVersionNumber;
FOUNDATION_EXPORT const unsigned char DateParserVersionString[];

