//
//  OpenDialog.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation
import Cocoa

class OpenDialog: NSObject {
    static func openCartridge() -> Data? {
        let openFileDialog = NSOpenPanel()
        openFileDialog.allowsMultipleSelection = false
        openFileDialog.canChooseDirectories = false
        openFileDialog.canCreateDirectories = false
        openFileDialog.canChooseFiles = true
        openFileDialog.allowedFileTypes = ["nes"]
        
        if openFileDialog.runModal().rawValue == NSApplication.ModalResponse.OK.rawValue {
            if let fileURL = openFileDialog.url {
                do {
                    let cartridgeData = try Data(contentsOf: fileURL)
                    return cartridgeData
                } catch {
                    print("Cartridge read error: \(fileURL.absoluteString)")
                }
            }
        }
        return nil
    }

}
