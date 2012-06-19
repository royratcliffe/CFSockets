// CFSockets CFSocket.m
//
// Copyright © 2009–2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "CFSocket.h"

@implementation CFSocket

@synthesize delegate = _delegate;

// designated initialiser
- (id)initWithSocketRef:(CFSocketRef)socket
{
	if ((self = [super init]))
	{
		if (socket)
		{
			_socket = socket;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (id)initWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol
{
	CFSocketContext context = { .info = (__bridge void *)self };
	return [self initWithSocketRef:CFSocketCreate(kCFAllocatorDefault, family, type, protocol, kCFSocketNoCallBack, __CFSocketCallOut, &context)];
}

- (id)initWithNativeHandle:(NSSocketNativeHandle)nativeHandle
{
	CFSocketContext context = { .info = (__bridge void *)self };
	return [self initWithSocketRef:CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, kCFSocketNoCallBack, __CFSocketCallOut, &context)];
}

- (BOOL)setAddress:(NSData *)addressData error:(NSError **)outError
{
	CFSocketError error = CFSocketSetAddress(_socket, (__bridge CFDataRef)addressData);
	BOOL success = (error == kCFSocketSuccess);
	if (!success)
	{
		if (outError && *outError == nil)
		{
			*outError = [NSError errorWithDomain:CFSocketErrorDomain code:error userInfo:nil];
		}
	}
	return success;
}

- (void)acceptNativeHandle:(NSSocketNativeHandle)nativeHandle
{
	id<CFSocketDelegate> delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(socket:acceptNativeHandle:)])
	{
		[delegate socket:self acceptNativeHandle:nativeHandle];
	}
}

- (void)dealloc
{
	// The de-allocator does not need to wonder if the underlying socket exists,
	// or not. By contract, the socket must exist. This assumes, of course, that
	// a failed initialisation sequence does not invoke the de-allocator.
	CFRelease(_socket);
	_socket = NULL;
}

@end

NSString *const CFSocketErrorDomain = @"CFSocketErrorDomain";

void __CFSocketCallOut(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
	switch (type)
	{
		case kCFSocketAcceptCallBack:
		{
			// Next Step meets Core Foundation socket native handle type in the
			// next statement. You can use them interchangeably. Apple
			// type-define both as int. They are really Unix socket
			// descriptors. The external interface uses the Next Step
			// definition, since the Next Step foundation framework is the most
			// immediate dependency.
			[(__bridge CFSocket *)info acceptNativeHandle:*(CFSocketNativeHandle *)data];
			break;
		}
		default:
			;
	}
}
