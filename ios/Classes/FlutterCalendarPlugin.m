#import "FlutterCalendarPlugin.h"
#import <flutter_calendar_plugin/flutter_calendar_plugin-Swift.h>

@implementation FlutterCalendarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCalendarPlugin registerWithRegistrar:registrar];
}
@end
