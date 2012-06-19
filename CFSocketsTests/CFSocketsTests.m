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

@implementation CFSocketsTests

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

@end
