// ClockDelegate.m
//
// Copyright Michael Schmidt. All rights reserved.


#import "ClockDelegate.h"

static unsigned componentFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;


@implementation ClockDelegate

- (NSDate *)currentDate {

    // Fixed date of iPhone introduction for screenshots:
    // return [NSDate dateWithTimeIntervalSinceReferenceDate:190024881.000000];
    return [NSDate date];
}


- (NSAttributedString *)currentTitleWithAttributes:(NSDictionary *)attributes {

    NSDateComponents *now = [[NSCalendar autoupdatingCurrentCalendar] components:componentFlags fromDate:[self currentDate]];
    NSString *key, *val;

    int hour = (int)now.hour;

    // Some hours have a special name
    if (now.minute == 0) {

        key = [NSString stringWithFormat:@"M%02d", hour % 24];
	    val = _I18N (key);
        
	    if (![val isEqualTo: key])
		    return [[NSAttributedString alloc] initWithString: val attributes: attributes];
    }

    // Does the fuzzy time show the current or next hour name?
    key = [NSString stringWithFormat:@"S%02dh", state % 100];

    if ([_I18N (key) isEqualTo:@"next"]) {

        hour += 1;
    }

    // Format string for current state
    key = [NSString stringWithFormat:@"S%02d", state % 100];
    NSString *format = _I18N (key);
    
    // Hour description
    key = [NSString stringWithFormat:@"H%02d", hour % 12];
    NSString *hour_name = _I18N (key);

    // Build fuzzy time description
    NSString *fuzzy_time = [NSString stringWithFormat: format, hour_name];

    return [[NSAttributedString alloc] initWithString: fuzzy_time
                                           attributes: @{NSFontAttributeName: [NSFont systemFontOfSize: 13]}];
}


- (void)clockTick:(NSTimer *)timer {

    NSDateComponents *now = [[NSCalendar autoupdatingCurrentCalendar] components:componentFlags fromDate:[self currentDate]];

    // Compute the current 30 seconds step of the current hour
    int step = (int)now.minute * 2 + (int)now.second / 30;
    int nextState;
    
    if (step < 2) {

        // ...during the first minute we stick at the full hour
        nextState = 0;
    }
    else if (2 <= step && step <= 5) {

        // ...special state before the first full 5 minutes
        nextState = 1;
    }
    else if (step < 116) {

        // ...rounding to full 5 minute steps
        nextState = 1 + ((step + 4) / 10);
    }
    else {

        // ...round to full next hour
        nextState = 13;
    }

    // Add the current hour to the state
    nextState += now.hour * 100;
    

    // Update if needed
    if (state != nextState) {

        state = nextState;
        clockItem.attributedTitle = [self currentTitleWithAttributes: @{NSFontAttributeName: [NSFont systemFontOfSize: 13]}];
    }
}


- (void)menuNeedsUpdate:(NSMenu *)menu {

    NSDate *now = [self currentDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    dateFormatter.dateStyle = NSDateFormatterFullStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateItem.title = [dateFormatter stringFromDate:now];
    
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    timeItem.title = [dateFormatter stringFromDate:now];
}


- (void)applicationWillFinishLaunching:(NSNotification *)note {

    // Create status bar item
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    clockItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    
    clockItem.title = @" ";
    [clockItem setHighlightMode:YES];
    clockItem.menu = clockMenu;
    [clockItem setHighlightMode:YES];
    
    state = -1;
    
    // Create a timer object
    clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(clockTick:)
                                                userInfo:nil
                                                 repeats:YES];
}

@end
