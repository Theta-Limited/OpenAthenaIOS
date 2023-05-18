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

#import "TIFFCompressionDecoder.h"
#import "TIFFCompressionEncoder.h"
#import "TIFFDeflateCompression.h"
#import "TIFFLZWCompression.h"
#import "TIFFPackbitsCompression.h"
#import "TIFFPredictor.h"
#import "TIFFRawCompression.h"
#import "TIFFUnsupportedCompression.h"
#import "TIFFByteReader.h"
#import "TIFFByteWriter.h"
#import "TIFFIOUtils.h"
#import "tiff-ios-Bridging-Header.h"
#import "TIFFFieldTagTypes.h"
#import "TIFFFieldTypes.h"
#import "TIFFFileDirectory.h"
#import "TIFFFileDirectoryEntry.h"
#import "TIFFImage.h"
#import "TIFFImageWindow.h"
#import "TIFFRasters.h"
#import "TIFFReader.h"
#import "TIFFWriter.h"
#import "tiff_ios.h"
#import "TIFFConstants.h"

FOUNDATION_EXPORT double tiff_iosVersionNumber;
FOUNDATION_EXPORT const unsigned char tiff_iosVersionString[];

