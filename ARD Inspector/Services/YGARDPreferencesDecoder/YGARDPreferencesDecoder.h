//
//  YGARDPreferencesDecoder.h
//  ARDInspector
//
//  Created by Yoann Gini on 19/06/13.
//  Copyright (c) 2013 Yoann Gini. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGARDPreferencesDecoder : NSObject

+ (NSDictionary*)decodePreferences:(NSDictionary*)preferences withMasterPassword:(NSString*)masterPassword  error:(NSError**)outError;

@end
