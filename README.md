# Jib

**A Julia implementation of Interactive Brokers API**

`Jib` is a native [Julia](https://julialang.org/) client that implements
[Interactive Brokers](https://www.interactivebrokers.com/) API to communicate with their
TWS or IBGateway.

It aims to be feature complete, though it does not support legacy versions:
_i.e._ only API versions `v100` and above are currently supported.
This limit may become even stricter in the future.

The package design follows the official C++/Java
[IB API](http://interactivebrokers.github.io/tws-api/),
which is based on an asynchronous request-response communication model
over a TCP socket.

### Installation
To install from GitHub:
```julia
] add https://github.com/lbilli/Jib.jl
```

### Usage
The user interacts mainly with these two object types:
- `Connection`: created after establishing a connection with the server and
  holding a reference to it.
- `Wrapper`: containing the methods that are executed when the server responses are processed.

Other data structures, such as `Contract` and `Order`, are implemented as Julia `struct`
that mirror the respective classes in the official IB API.

A complete minimal working example is shown.
For this code to work, an instance of the IB TWS or IBGateway needs to be running
on the local machine, listening on port `4002`.
**Note:** _demo_ or _paper_ account recommended!! :smirk:
```julia
using Jib

wrap = Jib.Wrapper(
         # Customized methods
         error= (id, errorCode, errorString) -> println("Error: $(something(id, "NA")) $errorCode $errorString"),

         nextValidId= (orderId) -> println("Next OrderId: $orderId"),

         managedAccounts= (accountsList) -> println("Managed Accounts: $accountsList")
       );

# Connect to the server with clientId = 1
ib = Jib.connect(4002, 1);

# Start a background Task to process the server responses
Jib.start_reader(ib, wrap);

# Define contract
contract = Jib.Contract(symbol="GOOG",
                        secType="STK",
                        exchange="SMART",
                        currency="USD");

# Define order
order = Jib.Order();
order.action        = "BUY"
order.totalQuantity = 10
order.orderType     = "LMT"
order.lmtPrice      = 1000

orderId = 1    # Should match whatever is returned by the server

# Send order
Jib.placeOrder(ib, orderId, contract, order)

# Disconnect
Jib.disconnect(ib)
```

##### Foreground vs. Background Processing
It is possible to process the server responses either within the main process
or in a separate background `Task`:
- **foreground processing** is triggered by invoking `Jib.check_all(ib, wrap)`.
  It is the user's responsability to call it on a **regular basis**,
  especially when data are streaming in.
- **background processing** is started by `Jib.start_reader(ib, wrap)`.
  A separate `Task` is started in the background, which monitors the connection and processes
  the responses as they arrive.

To avoid undesired effects, the two approaches should not be mixed together
on the same connection.

### Implementation Details
The package does not export any name, therefore any functions
or types described here need to be prefixed by `Jib.*`.

As Julia is not an object-oriented language, the functionality of the IB
`EClient` class is provided here by regular functions. In particular:
- `connect(port, clientId, connectOptions)`: establish a connection. Return
  a `Connection` object.
- `disconnect(::Connection)`: close the connection.
- `check_all(::Connection, ::Wrapper)`: process available responses, **not blocking**.
  Return the number of messages processed. **Needs to be called regularly**.
- `start_reader(::Connection, ::Wrapper)`: start a `Task` for background processing.
- all other methods that send specific requests to the server.
  Refer to the official IB `EClient` class documentation for details and method signatures.
  The only caveat is to remeber to pass a `Connection` as first argument: _e.g._
  `reqContractDetails(ib::Connection, reqId:Int, contract::Contract)`

##### [`Wrapper`](src/wrapper.jl)
Like the official IB `EWrapper` class, this `struct` holds the callbacks that are dispatched when
responses are processed.
By default it is filled with dummy functions. The user should override in the constructor
the desired methods, as shown in the [example](#usage) above.

A more comprehensive example is provided by [`simple_wrap()`](src/wrapper.jl),
which is used like this:
```julia
using Jib
using Jib: Contract, reqContractDetails, simple_wrap, start_reader

data, wrap = simple_wrap();

ib = Jib.connect(4002, 1);
start_reader(ib, wrap);

reqContractDetails(ib, 99, Contract(conId=208813720, exchange="SMART"))

# Wait for response and then access the "ContractDetails" result:
data[:cd]
```
Thanks to closures, `data` (a `Dict` in this case) is accessible by all
`wrap` methods as well as the main program. This way it is possible to easily
propagate the incoming data to different parts of the program.

For more details about callback definitions and signatures,
refer to the official IB `EWrapper` class documentation.
As reference, the exact signatures used in this package
are found [here](data/wrapper_signatures.jl).

#### Notes
Callbacks are generally invoked with arguments and types matching the signatures
as described in the official documentation.
However, there are few notable exceptions:
- `tickPrice()` has an extra `size::Int` argument,
  which is meaningful only when `TickType = {BID, ASK, LAST}`.
  In these cases, the official IB API fires an extra `tickSize()` event instead.
- `historicalData()` is invoked only once per request,
  presenting all the historical data as a single `DataFrame`,
  whereas the official IB API invokes it row-by-row.
- `scannerData()` is also invoked once per request and its arguments
  are in fact vectors rather than single values.

These modifications make it possible to establish the rule:
_one callback per server response_.

As a corollary, `historicalDataEnd()` and `scannerDataEnd()` are redundant and
thus are **not** used in this package.

`DataFrame` structures are also used as arguments in several other callbacks,
such as: `mktDepthExchanges()`, `smartComponents()`, `newsProviders()`, `histogramData()`,
`marketRule()` and the `historicalTicks*()` family.

##### Data Structures
Other classes that mainly hold data are also defined.
They are implemented as Julia `struct` or `mutable struct` with names,
types and default values matching the IB API counterparts.
Examples are `Contract`, `Order`, `ComboLeg`, `ExecutionFilter`, `ScannerSubscription`
and `Condition*`.

`TagValue` are implemented as Julia `NamedTuple`:
```julia
# Wherever a TagValue is needed, something like this can be used:
(tag1="value1", tag2="value2")
```
