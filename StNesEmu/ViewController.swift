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
    @IBOutlet weak var stepButton: NSButton!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var fpsTextView: NSTextField!
    
    var nes: Nes?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let nesView = screenView, let fpsView = fpsTextView {
            nes = Nes(renderer: CanvasRenderer(nesView: nesView, fpsView: fpsView), gameInputController: GameInputController())
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func clickLoadButton(_ sender: Any) {
        loadCartridge()
    }
    
    @IBAction func clickStepButton(_ sender: Any) {
        nes?.cpu?.run(true)
    }
    
    @IBAction func clickStartButton(_ sender: Any) {
        if let nes = nes {
            if nes.running {
                startButton?.title = "Start"
                nes.stop()
            }
            else {
                startButton?.title = "Stop"
                nes.start()
            }
        }
    }
    
    func loadCartridge() {
        if let fileData = OpenDialog.openCartridge() {
            if let cartridge = Parser.parse(fileData), let nes = nes {
                print("Cartridge: \(cartridge)")
                if nes.loadCartridge(cartridge) {
                    stepButton?.isEnabled = true
                    startButton?.isEnabled = true
                }
            }
            else {
                print("Failt to open file")
            }
        }
    }
}
