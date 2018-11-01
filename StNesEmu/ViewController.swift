//
//  ViewController.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var screenView: NSImageView!
    @IBOutlet weak var loadButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func clickLoadButton(_ sender: Any) {
        loadCartridge()
    }
    
    
    func loadCartridge() {
        if let fileData = OpenDialog.openCartridge() {
            if let cartridge = Parser.parse(fileData) {
                print("Cartridge: \(cartridge)")
            }
            else {
                print("Failt to open file")
            }
        }
    }
}

