# Core Foundation Sockets

[![Build Status](https://travis-ci.org/royratcliffe/CFSockets.png?branch=master)](https://travis-ci.org/royratcliffe/CFSockets)

The project has four targets: a Cocoa framework with its unit test bundle, an
iOS static library with its unit test bundle. The framework and the library
share the same source files. The sources use Automatic Reference Counting (ARC).

Why the plural project name? The project goes by the name 'Core Foundation
Sockets' rather than 'Core Foundation Socket.' This avoids confusion with
`CFSocket` which represents just one component of the CFSockets project. The
project's monolithic header imports as `<CFSockets/CFSockets.h>`. The
additional _s_ for the project prevents a clash with header
`<CFSockets/CFSocket.h>` which only imports the `CFSocket` class.
