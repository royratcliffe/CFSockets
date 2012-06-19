// CFSockets CFStreamPair.h
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class CFStreamPair;

@protocol CFStreamPairDelegate<NSObject>
@optional

- (void)streamPair:(CFStreamPair *)streamPair hasBytesAvailable:(NSUInteger)bytesAvailable;

- (void)streamPair:(CFStreamPair *)streamPair handleRequestEvent:(NSStreamEvent)eventCode;
- (void)streamPair:(CFStreamPair *)streamPair handleResponseEvent:(NSStreamEvent)eventCode;

@end

@interface CFStreamPair : NSObject<NSStreamDelegate>

@property(weak, NS_NONATOMIC_IOSONLY) id<CFStreamPairDelegate> delegate;
@property(strong, NS_NONATOMIC_IOSONLY) NSInputStream *requestStream;
@property(strong, NS_NONATOMIC_IOSONLY) NSOutputStream *responseStream;

- (id)initWithRequestStream:(NSInputStream *)requestStream responseStream:(NSOutputStream *)responseStream;
- (id)initWithSocketNativeHandle:(NSSocketNativeHandle)socketNativeHandle;

/*!
 * @details This method assumes that you have not already delegated, scheduled
 * or opened the underlying request-response stream pair.
 */
- (void)open;
- (void)close;

/*!
 * @brief Destructively receives bytes from the request buffer.
 */
- (NSData *)receiveAvailableBytes;

/*!
 * @brief Special convenience method for reading lines of text from the request
 * stream based on a given string encoding.
 * @details The result includes any line termination characters. There could be
 * more than one termination character at the end of the line since some line
 * termination sequences span multiple characters.
 * @result Answers @c nil if the request buffer does not yet contain a complete
 * line. Try again later.
 */
- (NSString *)receiveLineUsingEncoding:(NSStringEncoding)encoding;

- (void)sendBytes:(NSData *)outputBytes;

//-------------------------------------------------------------------- Overrides

- (void)hasBytesAvailable;
- (void)hasSpaceAvailable;
- (void)sendBytes;
- (void)handleRequestEvent:(NSStreamEvent)eventCode;
- (void)handleResponseEvent:(NSStreamEvent)eventCode;

@end
