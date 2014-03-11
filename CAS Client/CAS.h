//
//  CAS.h
//  CAS Client
//
//  Created by Chris Gibbs on 3/23/09.
//  Copyright Abilene Christian University 2009. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CAS : NSURLConnection

typedef void (^CASAuthCallbackBlock)(id param);

// CAS server info
@property (nonatomic, strong) NSString *casServer;
@property (nonatomic, strong) NSString *restletPath;
// User info
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
// CAS session data
@property (nonatomic, getter = isLoggedIn) BOOL loggedIn;
@property (nonatomic, strong) NSString *tgt;
// Authentication callback
@property (nonatomic, copy) CASAuthCallbackBlock authCallbackBlock;
// Temp connection data storage
@property (nonatomic, strong) NSMutableDictionary *connectionStorage;

+ (CAS *)client;
- (void)initWithCasServer:(NSString *)casServer
              restletPath:(NSString *)restletPath
                 username:(NSString *)username
                 password:(NSString *)password
        authCallbackBlock:(CASAuthCallbackBlock)authCallbackBlock;

- (void)requestTGTWithUsername:(NSString *)user
                      password:(NSString *)pass;

- (NSString *)requestSTForService:(NSURL *)serviceURL;

- (void)sendAsyncRequest:(NSURLRequest *)request
       authCallbackBlock:(CASAuthCallbackBlock)authCallbackBlock;

// NSURLConnection Delegate Methods
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse;

- (void) connection:(NSURLConnection *)connection
	 didReceiveData:(NSData *)data;

- (void) connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response;

- (void) connectionDidFinishLoading:(NSURLConnection *)connection;

@end
