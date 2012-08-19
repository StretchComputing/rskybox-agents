//
//  rSkybox.m
//  rTeam
//
//  Created by Nick Wroblewski on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "rSkybox.h"
#import "rSkyboxHelpers/JSON.h"
#import "UIDevice-Hardware.h"
#import "Encoder.h"
//TODO: rSkybox import - import your App Delegate .h file

static NSString *basicAuthUserName = @"token";
static NSString *baseUrl = @"https://rskybox-stretchcom.appspot.com/rest/v1";
static NSString *versionNumber = @"1.0";
//TODO: rSkybox ids - replace the current basicAuthToken and applicationId with the token and application id you received when you registered for rSkybox
static NSString *basicAuthToken = @"YOUR BASIC AUTH TOKEN GOES HERE";
static NSString *applicationId = @"YOUR RSKYBOX APPLICATION ID GOES HERE";

//Maximum number of App Actions to save
#define NUMBER_EVENTS_STORED 20


static NSMutableArray *traceSession;
static NSMutableArray *traceTimeStamps;

@implementation rSkybox

+ (NSString *)getUserId{
    //TODO: rSkybox userId - return instead a uniqiue identifier for this user
    return @"replaceWithRealUserId";
}

+ (NSDictionary *)createEndUser{
    
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
    NSString *statusReturn = @"";
    
    
    @try {
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:@"rTeam" forKey:@"application"];
        [tempDictionary setObject:versionNumber forKey:@"version"];
        
        
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONFragment], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/endUsers", applicationId];
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        SBJSON *jsonParser = [SBJSON new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if ([apiStatus isEqualToString:@"100"]) {
            //NSLog(@"Create End User Failed");
        }
        
        statusReturn = apiStatus;
        [returnDictionary setValue:statusReturn forKey:@"status"];
        return returnDictionary;
    }
    
    @catch (NSException *e) {
        statusReturn = @"1";
        [returnDictionary setValue:statusReturn forKey:@"status"];
        return returnDictionary;
    }
}


+(void)sendClientLog:(NSString *)logName logMessage:(NSString *)logMessage logLevel:(NSString *)logLevel exception:(NSException *)exception{
    
    @try {
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        //Fill parameter dictionary from input method parameters
        [tempDictionary setObject:logName  forKey:@"logName"];
        [tempDictionary setObject:logLevel forKey:@"logLevel"];
        [tempDictionary setObject:logMessage forKey:@"message"];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        
        //HardCoded at top of page
        [tempDictionary setObject:versionNumber forKey:@"version"];
        
        //Get the device and platform information, and add to a summary string
        float version = [[[UIDevice currentDevice] systemVersion] floatValue]; 
        NSString *platform = [[UIDevice currentDevice] platformString];
        NSString *summaryString = [NSString stringWithFormat:@"iOS Version: %f, Device: %@, App Version: %@", version, platform, versionNumber];
        [tempDictionary setObject:summaryString forKey:@"summary"];
        
        //Send in the current date
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        //If its an exception, send in the stackBackTrace in an array
        if (exception != nil) {
            NSMutableArray *stackTraceArray = [NSMutableArray array];
            NSArray *stackSymbols = [exception callStackSymbols];
            if(stackSymbols) {
                for (NSString *str in stackSymbols) {
                    
                    [stackTraceArray addObject:str];
                    
                }
            }
            
            [tempDictionary setObject:stackTraceArray  forKey:@"stackBackTrace"];
        }
        
        
        
        //Adding the App Actions
        NSMutableArray *finalArray = [NSMutableArray array];
        NSMutableArray *appActions = [NSMutableArray arrayWithArray:[rSkybox getActions]];
        NSMutableArray *appTimestamps = [NSMutableArray arrayWithArray:[rSkybox getTimestamps]];
        
        
        for (int i = 0; i < [appActions count]; i++) {
            NSMutableDictionary *actDictionary = [NSMutableDictionary dictionary];
            
            [actDictionary setObject:[appActions objectAtIndex:i] forKey:@"description"];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            NSString *dateString = [dateFormat stringFromDate:[appTimestamps objectAtIndex:i]];
            
            
            [actDictionary setObject:dateString forKey:@"timestamp"];
            
            
            [finalArray addObject:actDictionary];
            
        }
        
        [tempDictionary setObject:finalArray forKey:@"appActions"];        
        loginDict = tempDictionary;
        
        //Make the call to the server
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONFragment], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/clientLogs", applicationId];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        SBJSON *jsonParser = [SBJSON new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *logStatus = [response valueForKey:@"logStatus"];
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        
        if (![apiStatus isEqualToString:@"100"]) {
            //NSLog(@"Send Client Log Failed.");
        }
        
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *logChecklist = [NSMutableDictionary dictionaryWithDictionary:[standardUserDefaults valueForKey:@"logChecklist"]];
        
        //If the log is b
        if ([logStatus isEqualToString:@"inactive"]) {
            
            [logChecklist setObject:@"off" forKey:logName];
            [standardUserDefaults setObject:logChecklist forKey:@"logChecklist"];
            
            
        }
        
    }
    
    @catch (NSException *e) {
        
    }
}


+ (void)sendCrashDetect:(NSString *)summary theStackData:(NSData *)stackData{
    
    @try {
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:summary forKey:@"summary"];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:versionNumber forKey:@"version"];
        
        
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        
        
        if(stackData) {
            // stackData is hex and needs to be base64 encoded before packaged inside JSON
            NSString *encodedStackData = [rSkybox encodeBase64data:stackData];
            [tempDictionary setObject:encodedStackData forKey:@"stackData"];
        }
        
        //Adding the last 20 actions
        NSMutableArray *finalArray = [NSMutableArray array];
        NSMutableArray *appActions = [NSMutableArray arrayWithArray:[rSkybox getActions]];
        NSMutableArray *appTimestamps = [NSMutableArray arrayWithArray:[rSkybox getTimestamps]];
        
        
        for (int i = 0; i < [appActions count]; i++) {
            NSMutableDictionary *actDictionary = [NSMutableDictionary dictionary];
            
            [actDictionary setObject:[appActions objectAtIndex:i] forKey:@"description"];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            NSString *dateString = [dateFormat stringFromDate:[appTimestamps objectAtIndex:i]];
            
            [actDictionary setObject:dateString forKey:@"timestamp"];
            
            [finalArray addObject:actDictionary];
            
        }
        
        [tempDictionary setObject:finalArray forKey:@"appActions"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONFragment], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/crashDetects", applicationId];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        
        
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        
        SBJSON *jsonParser = [SBJSON new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if (![apiStatus isEqualToString:@"100"]) {
            // NSLog(@"Send Crash Failed.");
        }
    }
    
    @catch (NSException *e) {
        
        
    }
}



+(void)sendFeedback:(NSData *)recordedData{
    
    @try {
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        
        NSString *encodedRecordedData = [rSkybox encodeBase64data:recordedData];
        
        [tempDictionary setObject:encodedRecordedData forKey:@"voice"];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:versionNumber forKey:@"version"];
                
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONFragment], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/feedback", applicationId];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        SBJSON *jsonParser = [SBJSON new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if ([apiStatus isEqualToString:@"100"]) {
            //NSLog(@"Send Feedback Failed.");
        }
        
    }
    
    @catch (NSException *e) {
        
    }
}


//App Actions Methods
+(void)initiateSession{
    
    traceSession = [NSMutableArray array];
    traceTimeStamps = [NSMutableArray array];
    
}

+(void)addEventToSession:(NSString *)event{
    
    NSDate *myDate = [NSDate date];
    
    if ([traceSession count] < NUMBER_EVENTS_STORED) {
        [traceSession addObject:event];
        [traceTimeStamps addObject:myDate];
    }else{
        [traceSession removeObjectAtIndex:0];
        [traceSession addObject:event];
        [traceTimeStamps removeObject:0];
        [traceTimeStamps addObject:myDate];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd hh:mm:ss.SSS"];
    
    //TODO: rSkybox - instantiate your app delegate (uncomment the line below and replace MyAppDelegate with your app delegate);
    //MyAppDelegate *mainDelegate = (MyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *tmpTrace = @"";
    NSString *tmpTraceTime = @"";
    
    
    for (int i = 0; i < [traceSession count]; i++) {
        
        if (i == ([traceSession count] - 1)) {
            tmpTrace = [tmpTrace stringByAppendingFormat:@"%@", [traceSession objectAtIndex:i]];
            
            tmpTraceTime = [tmpTraceTime stringByAppendingFormat:@"%@", [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]]];
            
        }else{
            tmpTrace = [tmpTrace stringByAppendingFormat:@"%@,", [traceSession objectAtIndex:i]];
            tmpTraceTime = [tmpTraceTime stringByAppendingFormat:@"%@,", [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]]];
            
        }
    }
    
    mainDelegate.appActions = [NSString stringWithString:tmpTrace];
    mainDelegate.appActionsTime = [NSString stringWithString:tmpTraceTime];
    [mainDelegate saveUserInfo];
    
}

+(NSMutableArray *)getActions{
    
    return [NSMutableArray arrayWithArray:traceSession];
}

+(NSMutableArray *)getTimestamps{
    return [NSMutableArray arrayWithArray:traceTimeStamps];
    
}

+(void)setSavedArray:(NSMutableArray *)savedArray :(NSMutableArray *)savedArrayTime{
    
    traceSession = [NSMutableArray arrayWithArray:savedArray];
    traceTimeStamps = [NSMutableArray arrayWithArray:savedArrayTime];
}

+(void)printTraceSession{
    
    
    for (int i = 0; i < [traceSession count]; i++) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd hh:mm:ss.SSS"];
        NSString *dateString = [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]];
        
        NSLog(@"%d: %@ - %@", i, [traceSession objectAtIndex:i], dateString);
    }
    
}



//Take input binary and Base 64 encode it
+ (NSString *)encodeBase64data:(NSData *)encodeData{
	
    @try {
        //NSData *encodeData = [stringToEncode dataUsingEncoding:NSUTF8StringEncoding]
        char encodeArray[500000];
        
        memset(encodeArray, '\0', sizeof(encodeArray));
        
        // Base64 Encode username and password
        encode([encodeData length], (char *)[encodeData bytes], sizeof(encodeArray), encodeArray);
        NSString *dataStr = [NSString stringWithCString:encodeArray length:strlen(encodeArray)];
        
        // NSString *dataStr = [NSString stringWithCString:encodeArray encoding:NSUTF8StringEncoding];
        
        NSString *encodedString =[@"" stringByAppendingFormat:@"%@", dataStr];
        
        
        return encodedString;
    }
    @catch (NSException *e) {

        
        return @"";
    }
    
    
}

//Take a String and encode it in Base 64
+ (NSString *)encodeBase64:(NSString *)stringToEncode{
	
    @try {
        NSData *encodeData = [stringToEncode dataUsingEncoding:NSUTF8StringEncoding];
        char encodeArray[512];
        
        memset(encodeArray, '\0', sizeof(encodeArray));
        
        // Base64 Encode username and password
        encode([encodeData length], (char *)[encodeData bytes], sizeof(encodeArray), encodeArray);
        
        NSString *dataStr = [NSString stringWithCString:encodeArray length:strlen(encodeArray)];
        
        NSString *encodedString =[@"" stringByAppendingFormat:@"Basic %@", dataStr];
        
        return encodedString;
    }
    @catch (NSException *e) {
     
        
        return @"";
    }
    
}

//Initialize and return the Basic Authentication header
+(NSString *)getBasicAuthHeader {
    NSString *stringToEncode = [NSString stringWithFormat:@"%@:%@", basicAuthUserName, basicAuthToken];   
    
    NSString *encodedAuth = [rSkybox encodeBase64:stringToEncode];
    return encodedAuth;
}

@end




