// ClockDelegate.m
//
// Copyright Michael Schmidt. All rights reserved.


#import "ClockDelegate.h"


@implementation ClockDelegate


- (NSAttributedString*)currentTitleWithAttributes:(NSDictionary*)attributes
{
    NSCalendarDate *now = [NSCalendarDate calendarDate];
    int hour = [now hourOfDay];
    int day = [now dayOfWeek];

	NSString *key, *val;

    // Some hours have a special name
    if ([now minuteOfHour] == 0)
    {
        key = [NSString stringWithFormat:@"M%02d", hour % 24];
	    val = _I18N (key);
        
	    if (![val isEqualTo: key])
		    return [[NSAttributedString alloc] initWithString: val attributes: attributes];
    }

    // Does the fuzzy time show the current or next hour name?
    key = [NSString stringWithFormat:@"S%02dh", state % 100];
    if ([_I18N (key) isEqualTo:@"next"])
        hour += 1;
	
    // Format string for current state
    key = [NSString stringWithFormat:@"S%02d", state % 100];
    NSString *format = _I18N (key);
    
    // Hour description
    key = [NSString stringWithFormat:@"H%02d", hour % 12];
    NSString *hour_name = _I18N (key);
    
    // Day
    key = [NSString stringWithFormat:@"D%02d", day];
    NSString *day_name = _I18N(key);
    
    // Build fuzzy time description
    NSString *fuzzy_time = [NSString stringWithFormat: format, hour_name];

    return [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"%@, %@", day_name, fuzzy_time]
                                           attributes: @{NSFontAttributeName: [NSFont systemFontOfSize: 13]}];
}


- (void)clockTick:(NSTimer*)timer
{
    NSCalendarDate *now = [NSCalendarDate calendarDate];


    // Compute the current 30 seconds step of the current hour
    int step = [now minuteOfHour] * 2 + [now secondOfMinute] / 30;
    int nextState;
    
    // ...during the first minute we stick at the full hour
    if (step < 2)
        nextState = 0;
    
    // ...special state before the first full 5 minutes
    else if (2 <= step && step <= 5)
        nextState = 1;

    // ...rounding to full 5 minute steps
    else if (step < 116)
        nextState = 1 + ((step + 4) / 10);

    // ...round to full next hour
    else
        nextState = 13;      


    // Add the current hour to the state
    nextState += [now hourOfDay] * 100;
    

    // Update if needed
    if (state != nextState)
    {   
        state = nextState;

        [clockItem setAttributedTitle: [self currentTitleWithAttributes: @{NSFontAttributeName: [NSFont systemFontOfSize: 13]}]];
    }
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSCalendarDate *now            = [NSCalendarDate calendarDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle: NSDateFormatterFullStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    [dateItem setTitle: [dateFormatter stringFromDate: now]];
    
    [dateFormatter setDateStyle: NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle: NSDateFormatterMediumStyle];
    [timeItem setTitle: [dateFormatter stringFromDate: now]];
}


- (void)applicationWillFinishLaunching:(NSNotification *)note
{
    // Create status bar item
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    clockItem = [bar statusItemWithLength: NSVariableStatusItemLength];
    
    [clockItem setTitle: @" "];
    [clockItem setHighlightMode: YES];
    [clockItem setMenu: clockMenu];  
    [clockItem setHighlightMode: YES];
    
    state = -1;
    
    // Create a timer object
    clockTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                   target: self
                                                 selector: @selector(clockTick:)
                                                 userInfo: nil
                                                  repeats: YES];
}

@end
