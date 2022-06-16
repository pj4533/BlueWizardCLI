#import <Foundation/Foundation.h>
@class Buffer;

@interface Filterer : NSObject

-(instancetype)initWithBuffer:(Buffer *)buffer
            lowPassCutoffInHZ:(NSUInteger)lowPassCutoffInHZ
           highPassCutoffInHZ:(NSUInteger)highPassCutoffInHZ
                         gain:(float)gain;

-(Buffer *)process;

@end
