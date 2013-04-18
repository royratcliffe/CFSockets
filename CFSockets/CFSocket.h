// CFSockets CFSocket.h
//
// Copyright © 2009–2013, Roy Ratcliffe, Pioneering Software, United Kingdom
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
@class CFStreamPair;

@protocol CFSocketDelegate<NSObject>
@optional

- (void)socket:(CFSocket *)socket acceptNativeHandle:(NSSocketNativeHandle)nativeHandle;
- (void)socket:(CFSocket *)socket acceptStreamPair:(CFStreamPair *)streamPair;

@end

/**
 * Wraps Core Foundation's sockets in Objective-C clothing.
 *
 * Handles ARC memory management issues for a socket and implements a
 * delegation protocol. As an object, you can sub-class the socket. It papers
 * over the toll-free bridging requirements necessary for interactions between
 * Core Foundation and Foundation. Start by initialising a socket, either an
 * explicit IPv6 or IPv4 TCP socket, or whichever version of TCP socket the
 * system makes available to you. Note that IPv4 clients can also access IPv6
 * sockets.
 *
 * Note, you can have an object class called CFSocket; it does not clash with
 * Apple's Core Foundation C-based socket functions, externals and constants
 * because those exist in the C name space, while CFSocket here exists in the
 * Objective-C name space. They do not collide.
 */
@interface CFSocket : NSObject
{
	CFSocketRef _socket;
	CFRunLoopSourceRef _runLoopSource;
}

@property(weak, NS_NONATOMIC_IOSONLY) id<CFSocketDelegate> delegate;

/**
 * Designated initialiser.
 *
 * Initialisers also create the underlying Core Foundation socket. You
 * cannot have a partially initialised Objective-C socket. When socket creation
 * fails, initialisation fails also. All socket initialisers follow this
 * pattern. Hence, you cannot initialise a socket with a `NULL` socket
 * reference. In such cases, the initialiser answers `nil`.
 *
 * This approach creates a slight quandary. Creating a Core Foundation socket
 * requires a socket context. The context needs to retain a bridging reference
 * to `self`, the Objective-C object encapsulating the socket. Otherwise, the
 * socket call-back function cannot springboard from C to Objective-C when
 * call-backs trigger. When the initialiser returns successfully however, the
 * answer overwrites `self`. What if `self` changes? If it changes to `nil`,
 * no problem. But what if it changes to some other pointer address?
 *
 * TODO: Add more initialisers; specifically, socket signature initialisers.
 *
 * @param socket Reference to a CFSocket object.
 */
- (id)initWithSocketRef:(CFSocketRef)socket;

- (id)initWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol;
- (id)initForTCPv6;
- (id)initForTCPv4;

/**
 * Instantiates and creates a TCP socket using Internet Protocol version
 * 6 if available, else tries version 4.
 *
 * Starts by creating a socket for Internet Protocol version 6. This
 * also supports IPv4 clients via IPv4-mapped IPv6 addresses. Falls back to IPv4
 * only when IPv6 fails.
 *
 * @result Answers a TCP socket, version 6 or 4; returns `nil` if the socket
 * fails to create.
 */
- (id)initForTCP;

/**
 * Initialises using a native socket handle.
 * @param nativeHandle Platform-specific native socket handle.
 */
- (id)initWithNativeHandle:(NSSocketNativeHandle)nativeHandle;

/**
 * Binds an address to a socket.
 *
 * Despite the innocuous-sounding method name, this method irreversibly
 * binds the socket; assuming success. Do this early when constructing a
 * socket. Be aware that accessing the address also binds the socket, if not
 * already bound. You cannot therefore subsequently bind it. If you want to bind
 * to a specific port, do so by setting the socket address _before_ asking for
 * the address; that is, before using the getter method.
 */
- (BOOL)setAddress:(NSData *)addressData error:(NSError **)outError;

- (BOOL)connectToAddress:(NSData *)addressData timeout:(NSTimeInterval)timeout error:(NSError **)outError;

- (void)invalidate;
- (BOOL)isValid;
- (NSData *)address;
- (NSData *)peerAddress;
- (NSSocketNativeHandle)nativeHandle;
- (BOOL)setReuseAddressOption:(BOOL)flag;

/**
 * Answers the socket address family.
 *
 * For Internet-based sockets, answers either `AF_INET6` or
 * `AF_INET`. The latter for IP version 4 addresses. Note, protocol and address
 * family are one and the same for Internet addresses. Protocol families are
 * defined in terms of their address family; the `PF_` equals its corresponding
 * `AF_` manifest constant.
 *
 * You can use this for polymorphic behaviour. If behaviour depends on a
 * particular kind of socket, you can ask this method for the underlying address
 * family and respond accordingly. This method differs from -address which binds
 * the address first. The implementation here obtains the address family
 * non-destructively; socket state remains unchanged.
 *
 * @result Answers the socket address family, or `AF_MAX` when an error
 * occurs. On error, standard library `errno` value indicates the problem.
 */
- (int)addressFamily;

/**
 * Answers the port number.
 *
 * The answer depends on the socket's address family: version 4 or
 * 6. Handles the network-to-host byte ordering. The resulting integer has
 * correct ordering for the host machine.
 */
- (int)port;

- (void)addToCurrentRunLoopForCommonModes;
- (void)removeFromCurrentRunLoopForCommonModes;
- (void)disableAcceptCallBack;
- (void)enableAcceptCallBack;

/**
 * Handles the socket _accept_ call-back behaviour.
 *
 * Executes when Next Step meets Core Foundation. The argument specifies a
 * native socket handle, an integer defining the Unix socket descriptor.
 *
 * Exists to allow for optional overriding. You do not need to deploy
 * the delegate protocol if your sub-class handles "accept native handle" events
 * directly; though delegation usually works best.
 *
 * @param nativeHandle Platform-specific native socket handle.
 */
- (void)acceptNativeHandle:(NSSocketNativeHandle)nativeHandle;

@end

extern NSString *const CFSocketErrorDomain;

void __CFSocketCallOut(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
