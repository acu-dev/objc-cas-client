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

@synthesize casServer;
@synthesize restletPath;
@synthesize username;
@synthesize password;
@synthesize isLoggedIn;
@synthesize tgt;
@synthesize authCallbackObj;
@synthesize authCallbackSelector;
@synthesize connectionStorage;

# pragma mark Setup Methods

// Ensures that only one instance of casService is instantiated
+ (id) alloc {
	@synchronized(self) {
		NSAssert(casClient == nil, @"Attempted to allocate a second instance of CAS.");
		casClient = [super alloc];
		return casClient;
	}
	return nil;
}

// Allows the casService object to be shared asynchronously
+ (CAS *) client {
	@synchronized(self) {
		if (!casClient)
			[[CAS alloc] init];
		return casClient;
	}
	return nil;
}



#pragma mark CAS Methods

// Initialization of the shared casService
- (void) initWithCasServer:(NSString *)lCasServer 
			   restletPath:(NSString *)lRestletPath
				  username:(NSString *)lUsername
				  password:(NSString *)lPassword
		   authCallbackObj:(NSObject *)lAuthCallbackObj
	  authCallbackSelector:(SEL)lAuthCallbackSelector {
	
	// Initialize the instance vars with the local ones
	casServer = lCasServer;
	restletPath = lRestletPath;
	username = lUsername;
	password = lPassword;
	authCallbackObj = lAuthCallbackObj;
	authCallbackSelector = lAuthCallbackSelector;
	
	// Authenticate and get TGT
	[self requestTGTWithUsername:lUsername password:lPassword];
}

// Authenticates the user - if everything's good a TGT is set
// Called on initialization and when the TGT has expired
// Needs error checking
- (void) requestTGTWithUsername:(NSString *)user
					   password:(NSString *)pass {
	@synchronized(self) {
		// Create request
		NSLog(@"Requesting TGT from: %@", [casServer stringByAppendingString:restletPath]);
		NSString *credentials = [[[@"username=" stringByAppendingString:user] stringByAppendingString:@"&password="] stringByAppendingString:pass];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[casServer stringByAppendingString:restletPath]]];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody: [[NSString stringWithString:credentials] dataUsingEncoding: NSUTF8StringEncoding]];
		
		// Send request
		NSHTTPURLResponse *response;
		NSError *error;
		[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		// Get TGT from response header "Location"
		NSString *location;
		if (location = [[response allHeaderFields] valueForKey:@"Location"]) {
			NSString *ticket = [[location componentsSeparatedByString:@"/"] lastObject];
			NSLog(@"TGT Found: %@", ticket);
			[self setTgt:ticket];
		} else {
			NSLog(@"Problem getting the TGT from the response headers");
		}
		
		// Call the authenticationCallback
		[authCallbackObj performSelector:authCallbackSelector withObject:[NSNumber numberWithInt:[response statusCode]]];
	}
}

/*
 Requests a service ticket (ST) for a given service URL from the CAS server
 */
- (NSString *) requestSTForService:(NSURL *)serviceURL {
	if (!tgt) {
		NSString *err = @"ERROR: Can not get ST, no TGT found!";
		NSLog(@"%@", err);
		return err;
	}
	
	// Create request
	NSLog(@"Requesting ST for service: %@ at CAS URL: %@", serviceURL, [casServer stringByAppendingString:restletPath]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[casServer stringByAppendingString:restletPath] stringByAppendingString:tgt]]];
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
	NSString *st = [[[NSString alloc] initWithData:responseBody encoding: NSUTF8StringEncoding] autorelease];
	NSLog(@"ST: %@", st);
	
	return st;
}

/*
 Creates a connection and sets up objects for the data to be stored in when
 a response returns.
 */
- (void) sendAsyncRequest:(NSURLRequest *)request
			  callbackObj:(NSObject *)callbackObj
		 callbackSelector:(SEL)callbackSelector {
	
	// Convert selector to string for storage in the detail dictionary
	NSString *callbackSelectorStr = NSStringFromSelector(callbackSelector);
	
	// Connection objects
	NSURLResponse *response = [[NSURLResponse alloc] init];
	NSMutableData *data = [[NSMutableData alloc] init];
	
	// Create a detail dictionary for this connection
	NSMutableDictionary *connDetails = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 response, @"response",
								 data, @"data",
								 callbackSelectorStr, @"callbackSelector",
								 callbackObj, @"callbackObj",
								 nil];
	
	// Create the connection
	NSLog(@"Creating asynchronous request");
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
	
	// Store the connection dictionary
	if (connectionStorage == nil) {
		connectionStorage = [[NSMutableDictionary alloc] init];
	}		
	[[self connectionStorage] setValue:connDetails forKey:[conn description]];
}



# pragma mark NSURLConnection Delegate Methods

/*
 Sends a request to a given connection and handles CAS redirects
 */
- (NSURLRequest *) connection:(NSURLConnection *)connection
			  willSendRequest:(NSURLRequest *)request
			 redirectResponse:(NSURLResponse *)redirectResponse {
	
	NSURLRequest *newRequest = request;
    if (redirectResponse) {
		// Catch redirects to the CAS server
		NSString *redirectLocation = [[(NSHTTPURLResponse *)redirectResponse allHeaderFields] valueForKey:@"Location"];
		if ([[redirectLocation substringToIndex:[casServer length]] isEqualToString:casServer]) {
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
- (void) connection:(NSURLConnection *)connection
	 didReceiveData:(NSData *)data {
	
	//NSLog(@"connection:didReceiveData:");
	NSMutableData *storedData = [[connectionStorage objectForKey:[connection description]] objectForKey:@"data"];
	[storedData appendData:data];
}

/*
 Stores the connection response in the connection's storage dictionary
 */
- (void) connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response {
	
	//NSLog(@"connection:didReceiveResponse:");
	[[connectionStorage objectForKey:[connection description]] setObject:response forKey:@"response"];
}

/*
 Sends the final connection details to the callback object & selector. Removes
 connection details from storage.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"connectionDidFinishLoading:");
	NSDictionary *storedConnDetails = [connectionStorage objectForKey:[connection description]];
	
	// Get callback details
	NSObject *callbackObj = [storedConnDetails objectForKey:@"callbackObj"];
	SEL callbackSelector = NSSelectorFromString([storedConnDetails objectForKey:@"callbackSelector"]);
	
	// Message the callback with the results
	NSLog(@"Messaging the callback with the connection details");
	[callbackObj performSelector:callbackSelector withObject:storedConnDetails];
	
	// Cleanup
	[connectionStorage removeObjectForKey:[connection description]];
}


- (void)dealloc {
    [casServer release];
	[restletPath release];
	[username release];
	[password release];
	[tgt release];
	[authCallbackObj release];
	[connectionStorage release];
    [super dealloc];
}

@end
