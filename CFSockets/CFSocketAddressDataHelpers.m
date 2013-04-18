/* CFSockets CFSocketAddressDataHelpers.m
 *
 * Copyright © 2012, 2013, Roy Ratcliffe, Pioneering Software, United Kingdom
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the “Software”), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 ******************************************************************************/

#import "CFSocketAddressDataHelpers.h"

NSData *CFSocketAddressDataFromIPv6AddressWithPort(const struct in6_addr *addr, in_port_t port)
{
	struct sockaddr_in6 sockaddr;
	memset(&sockaddr, 0, sizeof(sockaddr));

	sockaddr.sin6_len = sizeof(sockaddr);
	sockaddr.sin6_family = AF_INET6;
	sockaddr.sin6_port = htons(port);
	memcpy(&sockaddr.sin6_addr, addr, sizeof(sockaddr.sin6_addr));

	return [NSData dataWithBytes:&sockaddr length:sizeof(sockaddr)];
}

NSData *CFSocketAddressDataFromAnyIPv6WithPort(in_port_t port)
{
	return CFSocketAddressDataFromIPv6AddressWithPort(&in6addr_any, port);
}

NSData *CFSocketAddressDataFromLoopBackIPv6WithPort(in_port_t port)
{
	return CFSocketAddressDataFromIPv6AddressWithPort(&in6addr_loopback, port);
}

NSData *CFSocketAddressDataFromIPv4AddressWithPort(in_addr_t addr, in_port_t port)
{
	struct sockaddr_in sockaddr;
	memset(&sockaddr, 0, sizeof(sockaddr));

	sockaddr.sin_len = sizeof(sockaddr);
	sockaddr.sin_family = AF_INET;
	sockaddr.sin_port = htons(port);
	sockaddr.sin_addr.s_addr = htonl(addr);

	return [NSData dataWithBytes:&sockaddr length:sizeof(sockaddr)];
}

NSData *CFSocketAddressDataFromAnyIPv4WithPort(in_port_t port)
{
	return CFSocketAddressDataFromIPv4AddressWithPort(INADDR_ANY, port);
}

NSData *CFSocketAddressDataFromLoopBackIPv4WithPort(in_port_t port)
{
	return CFSocketAddressDataFromIPv4AddressWithPort(INADDR_LOOPBACK, port);
}
