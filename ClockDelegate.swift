// ClockDelegate.swift
//
// Copyright Michael Schmidt. All rights reserved.

import Cocoa

@NSApplicationMain
class ClockDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var clockMenu: NSMenu!
    @IBOutlet weak var dateItem: NSMenuItem!
    @IBOutlet weak var timeItem: NSMenuItem!

    var clockItem: NSStatusItem?
    var clockTimer: Timer?

    var state: Int = -1 {
        didSet {
            clockItem?.attributedTitle = currentAttributedTitle()
        }
    }

    // Reads localized format strings for fuzzy time formatting
    func localizedString(format: String, value: Int) -> String? {

        let key = String(format: format, value)
        let localized = NSLocalizedString(key, comment: "")
        guard (localized != key) else { return nil }

        return localized
    }

    // Creates an attributed title string representing the current time as a fuzzy description
    func currentAttributedTitle() -> NSAttributedString {

        let now = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: NSDate() as Date)
        let attributes = [ NSFontAttributeName: NSFont.systemFont(ofSize: 13) ]

        // Some special hours may have a predefined title string like e.g. "midnight"
        if now.minute == 0 {
            if let title = localizedString(format: "M%02d", value:now.hour! % 24) {
                return NSAttributedString.init(string: title, attributes: attributes)
            }
        }

        // Time descriptions may refer to the current or the following hour
        let hourOffset : Int

        if localizedString(format: "S%02dh", value:state % 100) == "next" {
            hourOffset = 1
        }
        else {
            hourOffset = 0
        }

        // Build the fuzzy time description
        let title: String

        if let format = localizedString(format: "S%02d", value: state % 100),
           let hourName = localizedString(format: "H%02d", value: (now.hour! + hourOffset) % 12) {
            title = String(format: format, hourName)
        }
        else {
            title = "Error"
        }

        return NSAttributedString.init(string: title, attributes: attributes)
    }

    func clockTick() {

        let now = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: NSDate() as Date)

        // Compute the current 30 seconds step of the current hour
        let step = now.minute! * 2 + now.second! / 30

        // Next state of internal clock, initialized with information about current hour of day
        var nextState = now.hour! * 100;

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

        // Update only if needed
        if state != nextState {
            state = nextState
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {

        // Update menu contents with current date and time
        let now = NSDate() as Date
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        dateItem.title = dateFormatter.string(from: now)

        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        timeItem.title = dateFormatter.string(from: now)
    }

    func applicationWillFinishLaunching(_ aNotification: Notification) {

        // Create the status bar item
        let bar = NSStatusBar.system()
        clockItem = bar.statusItem(withLength: NSVariableStatusItemLength)
        clockItem?.title = " "
        clockItem?.menu = clockMenu
        clockItem?.highlightMode = true
        clockItem?.autosaveName = "me.mschmidt.FuzzyClock"
        clockItem?.behavior = [ .removalAllowed, .terminationOnRemoval ]

        // Install timer for clock updates
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in self.clockTick() }
    }
}
