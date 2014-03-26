Jasig CAS Client
=============
`Jasig CAS Client` demonstrates authentication using the [Jasig CAS RESTful API](https://wiki.jasig.org/display/CASUM/RESTful+API) within an iOS application.

Using the packaged iOS application
---
Update the following variables found in the `authenticate` method within `CAS Client/CASViewController.m` to use valid credentials and Jasig CAS server:
* `username`
* `password`
* `casServer`
* `casRestletPath`

How It Works
---
# `CAS.m`:`requestTGTWithUsername` submits credentials to the Jasig CAS RESTful API expecting either a `TicketGrantingTicket` or failed authentication response.
# `CAS.m`:`requestSTForService` submits `TicketGrantingTicket` to Jasig CAS RESTful API expecting either a `ServiceTicket` or unsuccessful response.
# `ServiceTicket` appended on CAS protected URIs (e.g. http://localhost/protected/index.html?ticket=ST-1-FFDFHDSJKHSDFJKSDHFJKRUEYREWUIFSD2132)

License
---
See the LICENSE file
