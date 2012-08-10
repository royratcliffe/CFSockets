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
#import "CFStreamPair.h"

// for setsockopt(2)
#import <sys/socket.h>

// for IPPROTO_TCP
#import <netinet/in.h>

@implementation CFSocket

@synthesize delegate = _delegate;

- (id)init
{
	return (self = nil);
}

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
	return [self initWithSocketRef:CFSocketCreate(kCFAllocatorDefault, family, type, protocol, kCFSocketAcceptCallBack, __CFSocketCallOut, &context)];
}

- (id)initForTCPv6
{
	return [self initWithProtocolFamily:PF_INET6 socketType:SOCK_STREAM protocol:IPPROTO_TCP];
}

- (id)initForTCPv4
{
	return [self initWithProtocolFamily:PF_INET socketType:SOCK_STREAM protocol:IPPROTO_TCP];
}

- (id)initForTCP
{
	self = [self initForTCPv6];
	if (self == nil) self = [self initForTCPv4];
	return self;
}

- (id)initWithNativeHandle:(NSSocketNativeHandle)nativeHandle
{
	CFSocketContext context = { .info = (__bridge void *)self };
	return [self initWithSocketRef:CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, kCFSocketAcceptCallBack, __CFSocketCallOut, &context)];
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

- (BOOL)connectToAddress:(NSData *)addressData timeout:(NSTimeInterval)timeout error:(NSError **)outError
{
	CFSocketError error = CFSocketConnectToAddress(_socket, (__bridge CFDataRef)addressData, timeout);
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

- (void)invalidate
{
	// Never close the underlying native socket without first invalidating.
	CFSocketInvalidate(_socket);
}

- (BOOL)isValid
{
	return CFSocketIsValid(_socket) != false;
}

- (NSData *)address
{
	return CFBridgingRelease(CFSocketCopyAddress(_socket));
}

- (NSData *)peerAddress
{
	return CFBridgingRelease(CFSocketCopyPeerAddress(_socket));
}

- (NSSocketNativeHandle)nativeHandle
{
	return CFSocketGetNative(_socket);
}

- (BOOL)setReuseAddressOption:(BOOL)flag
{
	int option = (flag == NO) ? 0 : 1;
	return 0 == setsockopt([self nativeHandle], SOL_SOCKET, SO_REUSEADDR, (void *)&option, sizeof(option));
}

- (int)addressFamily
{
	uint8_t sockaddr[SOCK_MAXADDRLEN];
	socklen_t len = sizeof(sockaddr);
	return 0 == getsockname([self nativeHandle], (struct sockaddr *)sockaddr, &len) && len >= offsetof(struct sockaddr, sa_data) ? ((struct sockaddr *)sockaddr)->sa_family : AF_MAX;
}

- (int)port
{
	int port;
	switch ([self addressFamily])
	{
		case AF_INET:
			port = ntohs(((struct sockaddr_in *)[[self address] bytes])->sin_port);
			break;
		case AF_INET6:
			port = ntohs(((struct sockaddr_in6 *)[[self address] bytes])->sin6_port);
			break;
		default:
			port = 0;
	}
	return port;
}

- (void)addToCurrentRunLoopForCommonModes
{
	// NSRunLoop is not toll-free bridged to CFRunLoop, even though their names
	// might suggest that they are.
	if (_runLoopSource == NULL)
	{
		_runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
	}
}

- (void)removeFromCurrentRunLoopForCommonModes
{
	if (_runLoopSource)
	{
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
		CFRelease(_runLoopSource);
		_runLoopSource = NULL;
	}
}

- (void)disableAcceptCallBack
{
	CFSocketDisableCallBacks(_socket, kCFSocketAcceptCallBack);
}

- (void)enableAcceptCallBack
{
	// The Read, Accept and Data callbacks are mutually exclusive.
	CFSocketEnableCallBacks(_socket, kCFSocketAcceptCallBack);
}

- (void)acceptNativeHandle:(NSSocketNativeHandle)nativeHandle
{
	id<CFSocketDelegate> delegate = [self delegate];
	if (delegate)
	{
		if ([delegate respondsToSelector:@selector(socket:acceptNativeHandle:)])
		{
			[delegate socket:self acceptNativeHandle:nativeHandle];
		}
		else if ([delegate respondsToSelector:@selector(socket:acceptStreamPair:)])
		{
			CFStreamPair *streamPair = [[CFStreamPair alloc] initWithSocketNativeHandle:nativeHandle];
			if (streamPair)
			{
				[delegate socket:self acceptStreamPair:streamPair];
			}
		}
		else
		{
			close(nativeHandle);
		}
	}
	else
	{
		close(nativeHandle);
	}
}

- (void)dealloc
{
	// The de-allocator does not need to wonder if the underlying socket exists,
	// or not. By contract, the socket must exist. This assumes, of course, that
	// a failed initialisation sequence does not invoke the
	// de-allocator. However, you cannot assume that. Assigning self to nil
	// under ARC de-allocates the instance and invokes the -dealloc method.
	[self removeFromCurrentRunLoopForCommonModes];
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
