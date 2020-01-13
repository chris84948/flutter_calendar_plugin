#import "FlutterCalendarPlugin.h"
#if __has_include(<flutter_calendar_plugin/flutter_calendar_plugin-Swift.h>)
#import <flutter_calendar_plugin/flutter_calendar_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_calendar_plugin-Swift.h"
#endif

@implementation FlutterCalendarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCalendarPlugin registerWithRegistrar:registrar];
}
@end
