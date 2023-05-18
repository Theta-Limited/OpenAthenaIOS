//
//  TIFFDeflateCompression.h
//  tiff-ios
//
//  Created by Brian Osborn on 1/9/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "TIFFCompressionDecoder.h"
#import "TIFFCompressionEncoder.h"

/**
 * Deflate Compression
 */
@interface TIFFDeflateCompression : NSObject<TIFFCompressionDecoder, TIFFCompressionEncoder>

@end
