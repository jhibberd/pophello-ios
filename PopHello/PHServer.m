
#import "MWLogging.h"
#import "PHServer.h"

static NSString *const kPHPropertyServerHost = @"ServerHost";

@implementation PHServer {
    NSString *_userID;
}

// Init
//
// All server API calls take place within the context of a user.
//
- (id)initWithUserID:(NSString *)userID
{
    self = [super init];
    if (self) {
        _userID = userID;
    }
    return self;
}

#pragma mark - Endpoints

// Return data for a set of tags near the current device's location.
//
- (void)queryForZoneTags:(CLLocationCoordinate2D)center
          successHandler:(void (^)(NSArray *tags))successHandler
            errorHandler:(void (^)(NSDictionary *response))errorHandler
{    
    NSString *query = [NSString stringWithFormat:@"lat=%f&lng=%f&user_id=%@",
                       center.latitude, center.longitude, _userID];
    NSURL *url = [self buildURLWithPath:@"/tags" query:query];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self dataTaskWithRequest:request successHandler:^(NSDictionary *response) {
        NSArray *tags = response[@"data"];
        successHandler(tags);

    } errorHandler:errorHandler];
}

// Post a new tag at the device's current location.
//
- (void)postTagAt:(CLLocationCoordinate2D)center
             text:(NSString *)text
   successHandler:(void (^)())successHandler
     errorHandler:(void (^)(NSDictionary *))errorHandler
{
    NSDictionary *body = @{@"user_id": _userID,
                           @"lat": @(center.latitude),
                           @"lng": @(center.longitude),
                           @"text": text};
    
    // JSON serialize the request body dictionary
    NSError *error = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:&error];
    if (!bodyData || error) {
        NSLog(@"failed to serialize data object");
        return;
    }
    
    // build the HTTP request
    NSURL *url = [self buildURLWithPath:@"/tags" query:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-type"];
    
    [self dataTaskWithRequest:request successHandler:^(NSDictionary *response) {
        successHandler();
        
    } errorHandler:errorHandler];

}

// Acknowledge that the user has consumed a tag.
//
// The user won't be presented with the tag again and the author will be notified.
//
- (void)acknowledgeTag:(NSString *)tagId
        successHandler:(void (^)())successHandler
          errorHandler:(void (^)(NSDictionary *))errorHandler
{
    NSString *query = [NSString stringWithFormat:@"user_id=%@", _userID];
    NSString *path = [NSString stringWithFormat:@"/tags/%@", tagId];
    NSURL *url = [self buildURLWithPath:path query:query];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    
    [self dataTaskWithRequest:request successHandler:^(NSDictionary *response) {
        successHandler();
        
    } errorHandler:errorHandler];
}


#pragma mark - HTTP Helpers

- (void)dataTaskWithRequest:(NSURLRequest *)request
             successHandler:(void (^)(NSDictionary *response))successHandler
               errorHandler:(void (^)(NSDictionary *response))errorHander
{
    MWLogInfo(@"Server request (method=%@, url=%@)", request.HTTPMethod, request.URL);
    
    // we're happy with the default session configuration
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
            MWLogInfo(@"Received server response (code=%ld)", (long)statusCode);
            
            if (error) {
                MWLogCritical(@"Server response is error (msg=%@)", [error localizedDescription]);
                
            } else {
                
                // we received a response from the server application so JSON-decode it
                NSError *errorSerialization = nil;
                NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:kNilOptions
                                                                                 error:&errorSerialization];
                if (errorSerialization) {
                    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    MWLogCritical(@"Failed to deserialize server JSON response (data=%@)", dataString);
                    errorHander(nil);
                    return;
                }
                
                // log the response then pass it to the appropriate handler
                if (statusCode != 200 && statusCode != 201) {
                    MWLogError(@"Server response is error (msg=%@)", dataDictionary);
                    errorHander(dataDictionary);
                    
                } else {
                    MWLogInfo(@"Server response is success (msg=%@)", dataDictionary);
                    successHandler(dataDictionary);
                }
            }
        }];
    [task resume];
}

- (NSURL *)buildURLWithPath:(NSString *)path query:(NSString *)query
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *host = [mainBundle objectForInfoDictionaryKey:kPHPropertyServerHost];
    
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"http";
    components.host = host;
    components.port = @4000;
    components.path = path;
    if (query) {
        components.query = query;
    }
    return [components URL];
}

@end
