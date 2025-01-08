# InteractiveBrokers

[![Build Status](https://github.com/oliviermilla/InteractiveBrokers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/oliviermilla/InteractiveBrokers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/oliviermilla/InteractiveBrokers.jl/graph/badge.svg?token=AFV1NV9CR9)](https://codecov.io/gh/oliviermilla/InteractiveBrokers.jl)

*A Julia implementation of Interactive Brokers API*

`InteractiveBrokers` is a native [Julia](https://julialang.org/) client that implements
[Interactive Brokers](https://www.interactivebrokers.com/) API to communicate
with TWS or IBGateway.

It aims to be feature complete, however it does not support legacy versions.
Currently, only API versions `v187+` are supported.

The package design follows the official C++/Java
[IB API](https://interactivebrokers.github.io/tws-api/),
which is based on an asynchronous communication model over TCP.

The package was first developed by lbilli in [Jib.jl](https://github.com/lbilli/Jib.jl).
lbilli still maintains his package and APIs and functionalities are integrated into InteractiveBrokers.jl.

What are the differences with Jib.jl then?
1. InteractiveBrokers.jl is published to Julia's General Repository.
2. DataFrame integration is done through an extension, allowing to keep the same API as Jib.jl but with lighter dependencies if you don't need DataFrames per se.
3. User-provided callbacks can have an optional object upon which to dispatch. (see example below)

The development of InteractiveBrokers.jl was first motivated to integrate InteractiveBrokers with [Lucky.jl](https://github.com/oliviermilla/Lucky.jl) trading framework.

### Installation
To install from Julia General Repository:
```julia
] add InteractiveBrokers.jl
```

To install from GitHub:
```julia
] add https://github.com/oliviermilla/InteractiveBrokers.jl
```

## Usage
The user interacts mainly with these two objects:
- `Connection`: a handle holding a connection to the server
- `Wrapper`: a container for the callbacks that are invoked
   when the server responses are processed.

Other data structures, such as `Contract` and `Order`, are implemented as Julia `struct`
and mirror the respective classes in the official IB API.

A complete minimal working example is shown.
For this code to work, an instance of IB TWS or IBGateway needs to be running
on the local machine and listening on port `4002`.
**Note:** _demo_ or _paper_ account recommended!! :smirk:
```julia
using InteractiveBrokers

wrap = InteractiveBrokers.Wrapper(
         # Customized methods go here
         error= (id, errorTime, errorCode, errorString, advancedOrderRejectJson) ->
                  println("Error: $(something(id, "NA")) $errorTime $errorCode $errorString $advancedOrderRejectJson"),

         nextValidId= (orderId) -> println("Next OrderId: $orderId"),

         managedAccounts= (accountsList) -> println("Managed Accounts: $accountsList")

         # more method overrides can go here...
       );

# Connect to the server with clientId = 1
ib = InteractiveBrokers.connect(4001, 1);

# Start a background Task to process the server responses
InteractiveBrokers.start_reader(ib, wrap);

# Define contract
contract = InteractiveBrokers.Contract(symbol="GOOG",
                        secType="STK",
                        exchange="SMART",
                        currency="USD");

# Define order
order = InteractiveBrokers.Order();
order.action        = "BUY"
order.totalQuantity = 10
order.orderType     = "LMT"
order.lmtPrice      = 100

orderId = 1    # Should match whatever is returned by the server

# Send order
InteractiveBrokers.placeOrder(ib, orderId, contract, order)

# Disconnect
InteractiveBrokers.disconnect(ib)
```

#### Foreground vs. Background Processing
It is possible to process the server responses either within the main process
or in a separate background `Task`:
- **foreground processing** is triggered by invoking `InteractiveBrokers.check_all(ib, wrap, Tab=Dict)`.
  It is the user's responsibility to call it on a **regular basis**,
  especially when data are streaming in.
- **background processing** is started by `InteractiveBrokers.start_reader(ib, wrap, Tab=Dict)`.
  A separate `Task` is started in the background, which monitors the connection and processes
  the responses as they arrive.

To avoid undesired effects, the two approaches should not be mixed together on the same connection.

### Sink Format
`Tab` parameter of above examples is the sink format used when applicable. The library supports an extension for 
DataFrames (just pass `DataFrame` as a last parameter), otherwise `Dict` is the default format.

## Implementation Details
The package does not export any name, therefore any functions
or types described here need to be prefixed by `InteractiveBrokers.*`.

As Julia is not an object-oriented language, the functionality of the IB
`EClient` class is provided here by regular functions. In particular:
- `connect(port, clientId, connectOptions)`: establish a connection and return
  a `Connection` object.
- `disconnect(::Connection)`: terminate the connection.
- `check_all(::Connection, ::Wrapper)`: process available responses, **not blocking**.
  Return the number of messages processed. **Needs to be called regularly!**
- `start_reader(::Connection, ::Wrapper)`: start a `Task` for background processing.
- methods that send specific requests to the server.
  Refer to the official IB `EClient` class documentation for further details and method signatures.
  The only caveat is to remember to pass a `Connection` as first argument: _e.g._
  `reqContractDetails(ib::Connection, reqId:Int, contract::Contract)`

#### [`Wrapper`](src/wrapper.jl)
Like the official IB `EWrapper` class, this `struct` holds the callbacks
that are dispatched when responses are processed.
The user provides the callback definitions as keyword arguments
in the constructor, as shown [above](#usage), and/or by setting
the property of an existing instance.

A more comprehensive example is provided by [`simple_wrap()`](src/wrapper.jl#L130),
which is used like this:
```julia
using InteractiveBrokers: InteractiveBrokers, Contract, reqContractDetails, simple_wrap, start_reader

data, wrap = simple_wrap();

ib = InteractiveBrokers.connect(4002, 1);
start_reader(ib, wrap);

reqContractDetails(ib, 99, Contract(conId=208813720, exchange="SMART"))

# Wait for the response and then access the "ContractDetails" result:
data[:cd]
```
Thanks to closures, `data` (a `Dict` in this case) is accessible by all
`wrap` methods as well as the main program. This is one way to
propagate incoming data to different parts of the program.

For more details about callback definitions and signatures,
refer to the official IB `EWrapper` class documentation.
As reference, the exact signatures used in this package
are found [here](data/wrapper_signatures.jl).

## Notes
Callbacks are generally invoked with arguments and types matching the signatures
as described in the official documentation.
However, there are few exceptions:
- `tickPrice()` has an extra `size::Float64` argument,
  which is meaningful only when `TickType ∈ {BID, ASK, LAST}`.
  In these cases, the official IB API fires an extra `tickSize()` event instead.
- `historicalData()` is invoked only once per request,
  presenting all the historical data as a single `Vector{Bar}`,
  whereas the official IB API invokes it row-by-row.
- `scannerData()` is also invoked once per request and its arguments
  are in fact vectors rather than single values.

These modifications make it possible to establish the rule:
_one callback per server response_.

Consequently, ~~`historicalDataEnd()`~~
(starting from `v196` it's sent in a separate message)
and `scannerDataEnd()` are redundant and are **not** used in this package.

#### Missing Values
Occasionally, for numerical types, there is the need to represent
the lack of a value.

IB API does not have a uniform solution across the board, but rather
it adopts a variety of sentinel values.
They can be either the plain `0` or the largest representable value
of a given type such as `2147483647` and `9223372036854775807`
for 32- and 64-bit integers respectively or `1.7976931348623157E308`
for 64-bit floating point.

This package makes an effort to use Julia built-in `Nothing`
in all circumstances.

#### Data Structures
Other classes that mainly hold data are also replicated.
They are implemented as Julia `struct` or `mutable struct` with names,
types and default values matching the IB API counterparts: _e.g._
`Contract`, `Order`, `ComboLeg`, `ExecutionFilter`, `ScannerSubscription`
and `Condition*`.

`TagValueList` are implemented as Julia `NamedTuple`.
Wherever a TagValue is needed, something like this can be used:
```julia
tagvaluelist = (tag1="value1", tag2="value2")
# or, in case of an empty list:
emptylist = (;)
```
Values don't need to be of type `String`. `Int` and `Float64` are also allowed.
