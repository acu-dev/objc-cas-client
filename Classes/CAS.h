//
//  CAS.h
//  CAS Client
//
//  Created by Chris Gibbs on 3/23/09.
//  Copyright Abilene Christian University 2009. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CAS : NSURLConnection {
	// CAS server info
	NSString *casServer;
	NSString *restletPath;
	
	// User info
	NSString *username;
	NSString *password;
	
	// CAS session data
	BOOL isLoggedIn;
	NSString *tgt;
	
	// Authentication callback
	NSObject *authCallbackObj;
	SEL authCallbackSelector;
	
	// Temp connection data storage
	NSMutableDictionary *connectionStorage;
}

@property (nonatomic, retain) NSString *casServer;
@property (nonatomic, retain) NSString *restletPath;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic, retain) NSString *tgt;
@property (nonatomic, copy) NSObject *authCallbackObj;
@property SEL authCallbackSelector;
@property (nonatomic, retain) NSMutableDictionary *connectionStorage;

+ (CAS *) client;
- (void) initWithCasServer:(NSString *)lCasServer
			   restletPath:(NSString *)lRestletPath
				  username:(NSString *)lUsername
				  password:(NSString *)lPassword
		   authCallbackObj:(NSObject *)lAuthCallbackObj
	  authCallbackSelector:(SEL)lAuthCallbackSelector;
- (void) requestTGTWithUsername:(NSString *)user
					   password:(NSString *)pass;
- (NSString *) requestSTForService:(NSURL *)serviceURL;
- (void) sendAsyncRequest:(NSURLRequest *)request
			  callbackObj:(NSObject *)callbackObj
		 callbackSelector:(SEL)callbackSelector;

// NSURLConnection Delegate Methods
- (NSURLRequest *) connection:(NSURLConnection *)connection
			  willSendRequest:(NSURLRequest *)request
			 redirectResponse:(NSURLResponse *)redirectResponse;
- (void) connection:(NSURLConnection *)connection
	 didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;

@end
