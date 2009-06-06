//
//  StorageHTTPConnection.h
//  Humboldt
//
//  Created by Peter Pistorius on 2009/02/06.
//  Copyright 2009 appfactory. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"HTTPConnection.h"
@class AFMultipartParser;


@interface StorageHTTPConnection : HTTPConnection {

	BOOL requestIsMultipart;
	AFMultipartParser *multipartParser;
}

// dealing with getting query variables....
- (NSMutableDictionary *)getQueryVariables:(NSString *)query escapePercentages:(BOOL)escape;
- (NSObject *)responseWithString:(NSString *)responseString;


// dealing with files...
- (NSString *)getRelativePath:(NSString *)path;
- (NSString *)getDirectoryItems:(NSString *)path;


@end
