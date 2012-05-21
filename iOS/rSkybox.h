//
//  rSkybox.h
//  rTeam
//
//  Created by Nick Wroblewski on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface rSkybox : NSObject

//rSkybox server communication methods
+ (NSDictionary *)createEndUser;
+(void)sendClientLog:(NSString *)logName logMessage:(NSString *)logMessage logLevel:(NSString *)logLevel exception:(NSException *)exception;
+(void)sendCrashDetect:(NSString *)summary theStackData:(NSData *)stackData;
+(void)sendFeedback:(NSData *)recordedData;




//App Actions Methods
+(void)initiateSession;
+(void)addEventToSession:(NSString *)event;
+(void)printTraceSession;
+(NSMutableArray *)getActions;
+(NSMutableArray *)getTimestamps;
+(void)setSavedArray:(NSMutableArray *)savedArray :(NSMutableArray *)savedArrayTime;

//Base64 Encoder methods
+ (NSString *)encodeBase64data:(NSData *)encodeData;
+ (NSString *)encodeBase64:(NSString *)stringToEncode;
+ (NSString *)getBasicAuthHeader;


@end
