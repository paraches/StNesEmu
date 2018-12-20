//
//  AppDelegate.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let rfDeviceMonitor = HIDDeviceMonitor([HIDMonitorData(vendorId: 1112, productId: 4098)], reportSize: 64)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let rfDeviceDaemon = Thread(target: self.rfDeviceMonitor, selector: #selector(self.rfDeviceMonitor.start), object: nil)
        rfDeviceDaemon.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

