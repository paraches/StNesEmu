//
//  NesTest.swift
//  StNesEmuTests
//
//  Created by paraches on 2018/11/20.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import XCTest
@testable import StNesEmu

class NesTest: XCTestCase {
    var cpu: CPU?
    var ppu: PPU?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        //
        //  Prepare nestest.nes cartridge and make CPU with it
        //
        guard let url = Bundle.main.url(forResource: "nestest", withExtension: "nes") else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        guard let cartridge = Parser.parse(data) else { return }
        
        let characterMem = RAM(memory: [UInt8](repeating: 0x00, count: 0x4000)) // Create 16K RAM
        for i in 0..<cartridge.characterROM.size() {
            let byteData: Byte = cartridge.characterROM.read(i)
            characterMem.write(i, byteData)
        }
        let ppuBus = PPU_BUS(characterRAM: characterMem)
        let interrupts = Interrupts()
        
        let ppu = PPU(bus: ppuBus, interrupts: interrupts, config: PPU.PPUConfig(isHorizontalMirror: false))
        self.ppu = ppu
        
        let wRam = RAM(memory: [UInt8](repeating: 0x00, count: 0x2000))
        let dma = DMA(ram: wRam, ppu: ppu)
        let cpubus = CPU_BUS(ram: wRam, programROM: cartridge.programROM, ppu: ppu, dma: dma)
        cpu = CPU(bus: cpubus, interrupts: interrupts)
        cpu?.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNesTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        let log = loadLog()
        XCTAssertTrue(log.count > 0)

        if let cpu = cpu {
            cpu.PC = 0xC000
            
            var stepNum = 1
            for state in log.dropLast() {
                cpu.run(true)
                if let stepInfo = Debugger.lastStep() {
                    XCTAssertEqual(stepInfo.cpu.A, state.a)
                    XCTAssertEqual(stepInfo.cpu.X, state.x)
                    XCTAssertEqual(stepInfo.cpu.Y, state.y)
                    XCTAssertEqual(stepInfo.cpu.P, state.p)
                    XCTAssertEqual(stepInfo.cpu.SP, state.sp)
                    if stepInfo.cpu.A != state.a ||
                        stepInfo.cpu.X != state.x ||
                        stepInfo.cpu.Y != state.y ||
                        stepInfo.cpu.P != state.p ||
                        stepInfo.cpu.SP != state.sp {
                        print("Error at step: \(stepNum)")
                        break
                    }
                }
                else {
                    print("stepInfo is not provided at step: \(stepNum)")
                }
                stepNum += 1
            }
            let v1: Byte = cpu.read(0x0002)
            let v2: Byte = cpu.read(0x0003)
            XCTAssertEqual(v1, 0x00)
            XCTAssertEqual(v2, 0x00)
        }
    }
}
