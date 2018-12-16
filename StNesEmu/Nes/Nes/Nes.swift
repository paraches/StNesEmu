//
//  Nes.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/03.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation
import QuartzCore

class Nes: NSObject {
    var renderer: CanvasRenderer
    var gameInputController: KeyPadSetProtocol
    
    var cpu: CPU?
    var ppu: PPU?
    var dma: DMA?
    
    private var loaded = false
    var running = false
    
    fileprivate var displayLink: CVDisplayLink?
    
    init(renderer: CanvasRenderer, gameInputController: KeyPadSetProtocol) {
        self.renderer = renderer
        self.gameInputController = gameInputController
        
        super.init()
        
        setUpCVDisplayLink()
    }
    
    func setUpCVDisplayLink() -> Void {
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            
            let nes = unsafeBitCast(displayLinkContext, to: Nes.self)
            
            //  Capture the current time in the currentTime property.
            nes.frame()
            
            //  We are going to assume that everything went well, and success as the CVReturn
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }
    
    @discardableResult
    func loadCartridge(_ cartridge: Cartridge) -> Bool {
        //
        // Create 16K RAM and copy character data from Cartridge
        //
        let characterMem = RAM(memory: [UInt8](repeating: 0x00, count: 0x4000)) // Create 16K RAM
        for i: Address in 0..<cartridge.characterROM.size() {
            let data: Byte = cartridge.characterROM.read(i)
            characterMem.write(i, data)
        }
        
        //
        //  PPU_BUS, Interrupts
        //
        let ppuBus = PPU_BUS(characterRAM: characterMem)
        let interrupts = Interrupts()
        
        self.ppu = PPU(bus: ppuBus, interrupts: interrupts, config: PPU.PPUConfig(isHorizontalMirror: false))
        guard let ppu = self.ppu else { return false }
        
        //
        //  Working RAM 2K
        //
        let wRam = RAM(memory: [UInt8](repeating: 0x00, count: 0x0800))
        
        self.dma = DMA(ram: wRam, ppu: ppu)
        guard let dma = dma else { return false }
        
        //
        //  KeyPad
        //
        let keyPad = KeyPad()
        self.gameInputController.setKeyPad(keyPad: keyPad)
        
        //
        //  CPU BUS
        //
        let cpubus = CPU_BUS(ram: wRam, programROM: cartridge.programROM, ppu: ppu, dma: dma, keyPad: keyPad)
        
        //
        //  CPU
        //
        cpu = CPU(bus: cpubus, interrupts: interrupts)
        cpu?.reset()
        
        loaded = cpu != nil
        return loaded
    }
    
    func frame() {
        guard let cpu = cpu, let dma = dma, let ppu = ppu else { return }
        while true {
            var cycle = 0
            if dma.isProcessing {
                dma.runDMA()
                cycle = ppu.cycle % 2 == 0 ? 513 : 514
            }
            cycle += cpu.run()
            if let renderingData = ppu.run(cycle * 3) {
                renderer.render(renderingData)
                break
            }
        }
    }
    
    func start() {
        if !running {
            running = true
            CVDisplayLinkStart(displayLink!)
        }
    }
    
    func stop() {
        if running {
            CVDisplayLinkStop(displayLink!)
            running = false
        }
    }
}
