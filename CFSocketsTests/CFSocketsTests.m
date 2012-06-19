// CFSocketsTests CFSocketsTests.m
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

#import "CFSocketsTests.h"

// import the monolithic header
#import <CFSockets/CFSockets.h>

@interface CFSocketsTests()

@property(strong, NS_NONATOMIC_IOSONLY) NSMutableSet *streamPairs;

@end

@implementation CFSocketsTests

@synthesize streamPairs;

- (void)setUp
{
	[self setStreamPairs:[NSMutableSet set]];
}

- (void)testVersionString
{
	// Just test for the existence of the version string, a simple
	// test. Disregard its contents.
	STAssertNotNil(CFSocketsVersionString(), nil);
}

- (void)testDefaultSocketInitialiser
{
	@autoreleasepool {
		CFSocket *socket = [[CFSocket alloc] init];
		STAssertNil(socket, nil);
	}
}

- (void)testSocketBindingToAnyAddressWithPort54321
{
	NSError *__autoreleasing error = nil;
	
	CFSocket *socket = [[CFSocket alloc] initForTCPv6];
	STAssertNotNil(socket, nil);
	
	// Clean up afterwards. Let the operating system quickly reclaim the port
	// after shutting down the socket.
	STAssertTrue([socket setReuseAddressOption:YES], nil);
	
	// Place a breakpoint after the following assert; with the unit test bundle
	// paused by the debugger, switch to Terminal and run "lsof -i" then you
	// will see an "otest" process with "TCP *:54321 (LISTEN)" meaning listening
	// on port 54321.
	STAssertTrue([socket setAddress:CFSocketAddressDataFromAnyIPv6WithPort(54321) error:&error], nil);
	STAssertNil(error, nil);
}

- (void)testSocketBindingToLoopBackIPv4AddressWithPort54321
{
	NSError *__autoreleasing error = nil;
	
	CFSocket *socket = [[CFSocket alloc] initForTCPv4];
	STAssertNotNil(socket, nil);
	
	STAssertTrue([socket setReuseAddressOption:YES], nil);
	
	// TCP localhost:54321 (LISTEN)
	STAssertTrue([socket setAddress:CFSocketAddressDataFromLoopBackIPv4WithPort(54321) error:&error], nil);
	STAssertNil(error, nil);
}

- (void)testServerSocket
{
	NSError *__autoreleasing error = nil;
	
	CFSocket *serverSocket = [[CFSocket alloc] initForTCPv6];
	STAssertNotNil(serverSocket, nil);
	STAssertTrue([serverSocket setReuseAddressOption:YES], nil);
	STAssertTrue([serverSocket setAddress:CFSocketAddressDataFromLoopBackIPv6WithPort(54321) error:&error], nil);
	STAssertNil(error, nil);
	
	// Run the server socket in a run-loop for 10 seconds. Make a connection to
	// the server using "telnet localhost 54321" at the command line. Enter a
	// line and you will see your message replied with a cryptic prefix. Beware
	// the Master Control Program!
	[serverSocket setDelegate:self];
	[serverSocket addToCurrentRunLoopForCommonModes];
	do
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
	}
	while ([[self streamPairs] count]);
}

- (void)socket:(CFSocket *)socket acceptStreamPair:(CFStreamPair *)streamPair
{
	// Important to retain the stream pair. Otherwise ARC will de-allocate and
	// reclaim its space.
	[[self streamPairs] addObject:streamPair];
	[streamPair setDelegate:self];
	[streamPair open];
}

- (void)streamPair:(CFStreamPair *)streamPair hasBytesAvailable:(NSUInteger)bytesAvailable
{
	NSString *line = [streamPair receiveLineUsingEncoding:NSUTF8StringEncoding];
	if (line)
	{
		[streamPair sendBytes:[[NSString stringWithFormat:@"MCP: %@", line] dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (void)streamPair:(CFStreamPair *)streamPair handleRequestEvent:(NSStreamEvent)eventCode
{
	switch (eventCode)
	{
		case NSStreamEventEndEncountered:
			// Important to un-retain the stream pair after the other end
			// terminates the connection. No point holding on to it. ARC will
			// automatically release it, and the stream pair will automatically
			// close itself.
			[[self streamPairs] removeObject:streamPair];
	}
}

@end
