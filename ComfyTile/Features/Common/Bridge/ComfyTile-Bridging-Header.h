//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <CoreGraphics/CoreGraphics.h>

// CoreDisplay (Intel only, fallback)
extern double CoreDisplay_Display_GetUserBrightness(CGDirectDisplayID id);
extern void CoreDisplay_Display_SetUserBrightness(CGDirectDisplayID id, double brightness);

// DisplayServices (Apple Silicon + Intel, preferred)
extern void DisplayServicesSetBrightness(CGDirectDisplayID display, float brightness);
extern void DisplayServicesGetBrightness(CGDirectDisplayID display, float *brightness);
