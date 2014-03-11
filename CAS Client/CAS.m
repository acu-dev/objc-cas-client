//
//  CAS.m
//  CAS Client
//
//  Created by Chris Gibbs on 3/23/09.
//  Copyright Abilene Christian University 2009. All rights reserved.
//

#import "CAS.h"

@implementation CAS

static CAS *casClient;

# pragma mark Setup Methods

// Ensures that only one instance of casService is instantiated
+ (id)alloc {
	@synchronized(self) {
		NSAssert(casClient == nil, @"Attempted to allocate a second instance of CAS.");
		casClient = [super alloc];
		return casClient;
	}
	return nil;
}

// Allows the casService object to be shared asynchronously
+ (CAS *)client {
	@synchronized(self) {
		if (!casClient)
			casClient = [[CAS alloc] init];
		return casClient;
	}
	return nil;
}

#pragma mark CAS Methods

// Initialization of the shared casService
- (void)initWithCasServer:(NSString *)casServer
              restletPath:(NSString *)restletPath
                 username:(NSString *)username
                 password:(NSString *)password
        authCallbackBlock:(CASAuthCallbackBlock)authCallbackBlock {

	_casServer = casServer;
	_restletPath = restletPath;
	_username = username;
	_password = password;
	_authCallbackBlock = authCallbackBlock;

	// Authenticate and get TGT
	[self requestTGTWithUsername:username password:password];
}

// Authenticates the user - if everything's good a TGT is set
// Called on initialization and when the TGT has expired
// Needs error checking
- (void)requestTGTWithUsername:(NSString *)user
                      password:(NSString *)pass {
	@synchronized(self) {
		// Create request
		NSLog(@"Requesting TGT from: %@", [self.casServer stringByAppendingString:self.restletPath]);
		NSString *credentials = [NSString stringWithFormat:@"%@%@%@%@", @"username=", user, @"&password=", pass];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                        [NSURL URLWithString:[self.casServer stringByAppendingString:self.restletPath]]];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody: [[NSString stringWithString:credentials] dataUsingEncoding: NSUTF8StringEncoding]];

		// Send request
		NSHTTPURLResponse *response;
		NSError *error;
		[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

		// Get TGT from response header "Location"
		NSString *location;
		if ((location = [[response allHeaderFields] valueForKey:@"Location"])) {
			NSString *ticket = [[location componentsSeparatedByString:@"/"] lastObject];
			NSLog(@"TGT Found: %@", ticket);
			[self setTgt:ticket];
		} else {
			NSLog(@"Problem getting the TGT from the response headers");
		}

		// Call the authenticationCallback
		self.authCallbackBlock(@([response statusCode]));
	}
}

/*
 Requests a service ticket (ST) for a given service URL from the CAS server
 */
- (NSString *)requestSTForService:(NSURL *)serviceURL {
	if (!self.tgt) {
		NSString *err = @"ERROR: Can not get ST, no TGT found!";
		NSLog(@"%@", err);
		return err;
	}

	// Create request
	NSLog(@"Requesting ST for service: %@ at CAS URL: %@", serviceURL, [self.casServer stringByAppendingString:self.restletPath]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:
                                                                        [[self.casServer stringByAppendingString:self.restletPath] stringByAppendingString:self.tgt]]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[@"service=" stringByAppendingString:[serviceURL description]] dataUsingEncoding:NSUTF8StringEncoding]];

	// Send request
	NSURLResponse *response;
	NSError *error;
	NSData *responseBody = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	//NSLog(@"ST Response Headers: %@", [(NSHTTPURLResponse *)response allHeaderFields]);

	// Check for unsuccessful response
	if ([(NSHTTPURLResponse *)response statusCode] != 200) {
		NSLog(@"ERROR: Unable to get ST");
		// TODO: request another TGT in case the one we have is expired
		// then call this again to see if you can get an ST
		// BUT ONLY ONCE
		return @"error";
	}

	// Get ST from response
	NSString *st = [[NSString alloc] initWithData:responseBody encoding: NSUTF8StringEncoding];
	NSLog(@"ST: %@", st);

	return st;
}

/*
 Creates a connection and sets up objects for the data to be stored in when
 a response returns.
 */
- (void)sendAsyncRequest:(NSURLRequest *)request
       authCallbackBlock:(CASAuthCallbackBlock)authCallbackBlock {

	// Connection objects
	NSURLResponse *response = [[NSURLResponse alloc] init];
	NSMutableData *data = [[NSMutableData alloc] init];
    
	// Create a detail dictionary for this connection
	NSMutableDictionary *connDetails = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        response, @"response",
                                        data, @"data",
                                        authCallbackBlock, @"authCallbackBlock", nil];
    
	// Create the connection
	NSLog(@"Creating asynchronous request");
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];

	// Store the connection dictionary
	if (self.connectionStorage == nil) {
		self.connectionStorage = [[NSMutableDictionary alloc] init];
	}
	[[self connectionStorage] setValue:connDetails forKey:[conn description]];
}



# pragma mark NSURLConnection Delegate Methods

/*
 Sends a request to a given connection and handles CAS redirects
 */
- (NSURLRequest *)connection:(NSURLConnection *)connection
			  willSendRequest:(NSURLRequest *)request
			 redirectResponse:(NSURLResponse *)redirectResponse {

	NSURLRequest *newRequest = request;
    if (redirectResponse) {
		// Catch redirects to the CAS server
		NSString *redirectLocation = [[(NSHTTPURLResponse *)redirectResponse allHeaderFields] valueForKey:@"Location"];
		if ([[redirectLocation substringToIndex:[self.casServer length]] isEqualToString:self.casServer]) {
			NSLog(@"CAUGHT CAS REDIRECT");
			// Get a service ticket and form a new request to return with it
			NSString *st = [self requestSTForService:[redirectResponse URL]];
			newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[[[[redirectResponse URL] description] stringByAppendingString:@"?ticket="] stringByAppendingString:st]]];
		}

    }
    return newRequest;
}


/*
 Connection loads data incrementally - This should concatenate the contents
 of each data object delivered to build up the complete data for a URL load.
 */
- (void)connection:(NSURLConnection *)connection
	 didReceiveData:(NSData *)data {

	//NSLog(@"connection:didReceiveData:");
	NSMutableData *storedData = self.connectionStorage[[connection description]][@"data"];
	[storedData appendData:data];
}

/*
 Stores the connection response in the connection's storage dictionary
 */
- (void)connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response {

	//NSLog(@"connection:didReceiveResponse:");
	self.connectionStorage[[connection description]][@"response"] = response;
}

/*
 Sends the final connection details to the callback object & selector. Removes
 connection details from storage.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"connectionDidFinishLoading:");
	NSDictionary *storedConnDetails = self.connectionStorage[[connection description]];

	// Get callback details
	CASAuthCallbackBlock authCallbackBlock = storedConnDetails[@"authCallbackBlock"];

	// Call the callback block with the results
	NSLog(@"Calling the callback block with the connection details");
	authCallbackBlock(storedConnDetails);

	// Cleanup
	[self.connectionStorage removeObjectForKey:[connection description]];
}

@end
