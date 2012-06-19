// CFSockets CFStreamPair.m
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

#import "CFStreamPair.h"

@interface CFStreamPair()

// You would not normally access the buffers directly. The following exposes the
// buffer implementation, albeit away from the public header: just a pair of
// mutable data objects.
@property(strong, NS_NONATOMIC_IOSONLY) NSMutableData *requestBuffer;
@property(strong, NS_NONATOMIC_IOSONLY) NSMutableData *responseBuffer;

@end

@implementation CFStreamPair

@synthesize delegate = _delegate;

// streams
@synthesize requestStream = _requestStream;
@synthesize responseStream = _responseStream;

// buffers
@synthesize requestBuffer = _requestBuffer;
@synthesize responseBuffer = _responseBuffer;

// designated initialiser
- (id)init
{
	if ((self = [super init]))
	{
		// Sets up the request and response buffers at the outset. You can ask
		// for available request bytes even before the request stream
		// opens. Similarly, you can send response bytes even before the
		// response opens. Hard to imagine exactly why however. Still, there is
		// nothing to say that we can assume that the response stream will open
		// before the request opens, or vice versa; indeed, the delegate may
		// even respond by sending some bytes even before the response stream
		// becomes ready. The buffer pair make such behaviour a valid pattern.
		[self setRequestBuffer:[NSMutableData data]];
		[self setResponseBuffer:[NSMutableData data]];
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

// convenience initialiser
- (id)initWithRequestStream:(NSInputStream *)requestStream responseStream:(NSOutputStream *)responseStream
{
	self = [self init];
	if (self)
	{
		[self setRequestStream:requestStream];
		[self setResponseStream:responseStream];
	}
	return self;
}

- (id)initWithSocketNativeHandle:(NSSocketNativeHandle)socketNativeHandle
{
	if ((self = [self init]))
	{
		CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, socketNativeHandle, &readStream, &writeStream);
		if (readStream && writeStream)
		{
			CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			[self setRequestStream:CFBridgingRelease(readStream)];
			[self setResponseStream:CFBridgingRelease(writeStream)];
		}
		else
		{
			if (readStream) CFRelease(readStream);
			if (writeStream) CFRelease(writeStream);
			
			// Something went wrong. Answer nil. Bear in mind however that this
			// does not mean that the de-allocation method will not run: it
			// will run.
			self = nil;
		}
	}
	return self;
}

- (void)open
{
	for (NSStream *stream in [NSArray arrayWithObjects:[self requestStream], [self responseStream], nil])
	{
		[stream setDelegate:self];
		
		[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[stream open];
	}
}

- (void)close
{
	// Send -close first. Closing may trigger events. Let the stream emit all
	// events until closing finishes. Might be wise to check the stream status
	// first, before attempting to close the stream. The de-allocator invokes
	// -close and therefore may send a double-close if the pair has already
	// received an explicit -close message.
	for (NSStream *stream in [NSArray arrayWithObjects:[self requestStream], [self responseStream], nil])
	{
		[stream close];
		[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	}
}

- (NSData *)receiveAvailableBytes
{
	NSData *bytes = [[self requestBuffer] copy];
	[[self requestBuffer] setLength:0];
	return bytes;
}

- (NSString *)receiveLineUsingEncoding:(NSStringEncoding)encoding
{
	// The implementation first converts all the request bytes to a string. This
	// could be risky for multi-byte characters. The implementation effectively
	// assumes that multi-byte characters do not cross buffer boundaries.
	//
	// When the request range has length equal to zero, sending
	// -lineRangeForRange: searches for the first line. The final bit is
	// tricky. How to dissect the line from any remaining characters? Simply
	// convert the remaining characters back to data using the given encoding.
	NSString *result;
	NSString *requestString = [[NSString alloc] initWithData:[self requestBuffer] encoding:encoding];
	NSRange lineRange = [requestString lineRangeForRange:NSMakeRange(0, 0)];
	if (lineRange.length)
	{
		[[self requestBuffer] setData:[[requestString substringFromIndex:lineRange.length] dataUsingEncoding:encoding]];
		result = [requestString substringToIndex:lineRange.length];
	}
	else
	{
		result = nil;
	}
	return result;
}

- (void)sendBytes:(NSData *)responseBytes
{
	[[self responseBuffer] appendData:responseBytes];
	
	// Trigger a "has space available" event if the response stream reports
	// available space at this point.
	if ([[self responseStream] hasSpaceAvailable])
	{
		[self hasSpaceAvailable];
	}
}

#pragma mark -
#pragma mark Overrides

- (void)hasBytesAvailable
{
	if ([[self requestBuffer] length])
	{
		id delegate = [self delegate];
		if (delegate && [delegate respondsToSelector:@selector(streamPair:hasBytesAvailable:)])
		{
			[delegate streamPair:self hasBytesAvailable:[[self requestBuffer] length]];
		}
	}
}

- (void)hasSpaceAvailable
{
	// Note that writing zero bytes to the response stream closes the
	// connection. Therefore, avoid sending nothing unless you want to close.
	if ([[self responseBuffer] length])
	{
		[self sendBytes];
	}
}

- (void)sendBytes
{
	NSMutableData *responseBuffer = [self responseBuffer];
	NSInteger bytesSent = [[self responseStream] write:[responseBuffer bytes] maxLength:[responseBuffer length]];
	if (bytesSent > 0)
	{
		[responseBuffer replaceBytesInRange:NSMakeRange(0, bytesSent) withBytes:NULL length:0];
	}
}

- (void)handleRequestEvent:(NSStreamEvent)eventCode
{
	switch (eventCode)
	{
		case NSStreamEventHasBytesAvailable:
		{
			uint8_t bytes[4096];
			NSInteger bytesAvailable = [[self requestStream] read:bytes maxLength:sizeof(bytes)];
			// Do not send a -read:maxLength message unless the stream reports
			// that it has bytes available. Always send this message at least
			// once when the bytes-available event fires, i.e. right now. The
			// stream event indicates that available bytes have already been
			// sensed. Avoid asking again.
			//
			// What happens however if more bytes arrive while reading, or the
			// available bytes overflow the stack-based temporary buffer? In
			// these cases, after reading, ask if more bytes exist. Issue
			// another read if they do, and repeat while they do.
			while (bytesAvailable > 0)
			{
				[[self requestBuffer] appendBytes:bytes length:bytesAvailable];
				if ([[self requestStream] hasBytesAvailable])
				{
					bytesAvailable = [[self requestStream] read:bytes maxLength:sizeof(bytes)];
				}
				else
				{
					bytesAvailable = 0;
				}
			}
			// Please note, the delegate can receive an has-bytes-available
			// event immediately followed by an error event.
			[self hasBytesAvailable];
			if (bytesAvailable < 0)
			{
				
			}
			break;
		}
		default:
			;
	}
	
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(streamPair:handleRequestEvent:)])
	{
		[delegate streamPair:self handleRequestEvent:eventCode];
	}
}

- (void)handleResponseEvent:(NSStreamEvent)eventCode
{
	switch (eventCode)
	{
		case NSStreamEventHasSpaceAvailable:
		{
			[self hasSpaceAvailable];
			break;
		}
		default:
			;
	}
	
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(streamPair:handleResponseEvent:)])
	{
		[delegate streamPair:self handleResponseEvent:eventCode];
	}
}

#pragma mark -
#pragma mark Stream Delegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	if (stream == [self requestStream])
	{
		[self handleRequestEvent:eventCode];
	}
	else if (stream == [self responseStream])
	{
		[self handleResponseEvent:eventCode];
	}
	else
	{
		;
	}
}

@end
