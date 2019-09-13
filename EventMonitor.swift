//
//  EventMonitor.swift
//  Mirabilis
//
//  Created by Onur Ersen on 11/08/16.
//  Copyright © 2016 Berat Onur Ersen. All rights reserved.
//

import Cocoa

public class EventMonitor {
    
        private var monitor: AnyObject?
        private let mask: NSEventMask
        private let handler: NSEvent? -> ()
        
        public init(mask: NSEventMask, handler: NSEvent? -> ()) {
            self.mask = mask
            self.handler = handler
        }
        
        deinit {
            stop()
        }
        
        public func start() {
            monitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: handler)
        }
        
        public func stop() {
            if monitor != nil {
                NSEvent.removeMonitor(monitor!)
                monitor = nil
            }
        }
    
}
