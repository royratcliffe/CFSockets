// CFSockets CFSocket.h
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

#import <Foundation/Foundation.h>

@class CFSocket;

@protocol CFSocketDelegate<NSObject>
@optional

- (void)socket:(CFSocket *)socket acceptNativeHandle:(NSSocketNativeHandle)nativeHandle;

@end

/*!
 * Note, you can have an object class called CFSocket; it does not clash with
 * Apple's Core Foundation C-based socket functions, externals and constants
 * because those exist in the C name space, while CFSocket here exists in the
 * Objective-C name space. They do not collide.
 */
@interface CFSocket : NSObject
{
	CFSocketRef _socket;
}

@property(weak, NS_NONATOMIC_IOSONLY) id<CFSocketDelegate> delegate;

/*!
 * Initialisers also create the underlying Core Foundation socket. You cannot
 * have a partially initialised Objective-C socket. When socket creation fails,
 * initialisation fails also. All socket initialisers follow this
 * pattern. Hence, you cannot initialise a socket with a NULL socket
 * reference. In such cases, the initialiser answers @c nil.
 *
 * This approach creates a slight quandary. Creating a Core Foundation socket
 * requires a socket context. The context needs to retain a bridging reference
 * to @c self, the Objective-C object encapsulating the socket. Otherwise, the
 * socket call-back function cannot springboard from C to Objective-C when
 * call-backs trigger. When the initialiser returns successfully however, the
 * answer overwrites @c self. What if @c self changes? If it changes to @c nil,
 * no problem. But what if it changes to some other pointer address?
 */
- (id)initWithSocketRef:(CFSocketRef)socket;
- (id)initWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol;
- (id)initWithNativeHandle:(NSSocketNativeHandle)nativeHandle;

- (void)acceptNativeHandle:(NSSocketNativeHandle)nativeHandle;

@end

extern NSString *const CFSocketErrorDomain;

void __CFSocketCallOut(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
