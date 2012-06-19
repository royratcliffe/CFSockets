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

- (id)initWithSocketRef:(CFSocketRef)socket
{
	if ((self = [self init]))
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
	if (_socket)
	{
		CFRelease(_socket);
		_socket = NULL;
	}
}

@end

NSString *const CFSocketErrorDomain = @"CFSocketErrorDomain";

void __CFSocketCallOut(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
	switch (type)
	{
		case kCFSocketAcceptCallBack:
		{
			[(__bridge CFSocket *)info acceptNativeHandle:*(CFSocketNativeHandle *)data];
			break;
		}
		default:
			;
	}
}
