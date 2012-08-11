// ClockDelegate.h
//
// Copyright Michael Schmidt. All rights reserved.


@interface ClockDelegate : NSObject
{
    int state;

    NSStatusItem *clockItem;
    NSTimer      *clockTimer;
    
    IBOutlet NSMenu     *clockMenu;
    IBOutlet NSMenuItem *dateItem;
    IBOutlet NSMenuItem *timeItem;
}

@end
