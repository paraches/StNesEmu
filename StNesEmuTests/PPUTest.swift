//
//  PPUTest.swift
//  StNesEmuTests
//
//  Created by paraches on 2018/11/24.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import XCTest
@testable import StNesEmu

class PPUTest: XCTestCase {
    
    var cpu: CPU?
    var ppu: PPU?
    var dma: DMA?
    
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
        self.dma = dma
        
        let cpubus = CPU_BUS(ram: wRam, programROM: cartridge.programROM, ppu: ppu, dma: dma)
        cpu = CPU(bus: cpubus, interrupts: interrupts)
        cpu?.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPPUCtrlTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }
        
        cpu.write(.ppuCtrl, Byte(0x3E))
        XCTAssertEqual(ppu.registers[0], 0x3E)
        XCTAssertEqual(ppu.vRAMOffset, 32)
        XCTAssertEqual(ppu.spriteTableOffset, 0x1000)
        XCTAssertEqual(ppu.backgroundTableOffset, 0x1000)
    }

    func testPPUMaskTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }

        cpu.write(.ppucMask, Byte(0xFF))
        XCTAssertEqual(ppu.registers[1], 0xFF)
        XCTAssertTrue(ppu.isBackgroundEnable)
        XCTAssertTrue(ppu.isSpriteEnable)
    }
    
    func testPPUStatusTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }
        
        ppu.setSpriteHit()
        ppu.setVBlank()
        
        let v1: Byte = cpu.read(.ppuStatus)
        XCTAssertEqual(v1, 0xC0)
        
        cpu.write(.ppuCtrl, Byte(0x0F))
        
        let _: Byte = cpu.read(.ppuStatus)
        XCTAssertFalse(ppu.isVBlank())
    }
    
    func testOAMAddressTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }
        
        cpu.write(.oamAddress, Byte(0x3E))
        XCTAssertEqual(ppu.spriteRAMAddr, 0x3E)
    }
    
    func testOAMDataTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }
        
        cpu.write(.oamAddress, Byte(0x00))
        cpu.write(.oamData, Byte(0xAA))
        
        XCTAssertEqual(ppu.spriteRAM.memory[0], 0xAA)
        XCTAssertEqual(ppu.spriteRAMAddr, 0x01)
    }
    
    func testOAMData2Test() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }

        cpu.write(.oamAddress, Byte(0x00))
        ppu.spriteRAM.memory[0] = 0xAA
        
        let v1: Byte = cpu.read(.oamData)
        XCTAssertEqual(v1, 0xAA)
    }
    
    func testPPUScrollTest() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }

        cpu.write(.ppuScroll, Byte(0x7D))
        
        XCTAssertFalse(ppu.isLowerVRAMAddr)
        XCTAssertFalse(ppu.isValidVRAMAddr)
        
        cpu.write(.ppuScroll, Byte(0x5E))
        XCTAssertEqual(ppu.scrollY, 0x5E)
    }
    
    func testPPUScrollandPPUAddress() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }

        cpu.write(.ppuScroll, Byte(0x7D))
        cpu.write(.ppuScroll, Byte(0x5E))
        
        cpu.write(.ppuAddress, Byte(0x3D))
        cpu.write(.ppuAddress, Byte(0xF0))
        
        XCTAssertEqual(ppu.vRAMAddr, 0x3DF0)
    }
    
    func testCPUreadPPUData() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }

        ppu.vRAMAddr = 0x0000
        ppu.vRAMReadBuf = 0xAA
        ppu.write(ppu.vRAMAddr, Byte(0x12))
        
        XCTAssertEqual(ppu.vRAMReadBuf, 0xAA)
        
        
        ppu.vRAMAddr = 0x0000
        ppu.vRAMReadBuf = 0xAA
        ppu.write(ppu.vRAMAddr, Byte(0x12))
        ppu.registers[0][2] = false
        
        let _: Byte = cpu.read(.ppuData)
        XCTAssertEqual(ppu.vRAMAddr, 0x0001)


        ppu.vRAMAddr = 0x0000
        ppu.vRAMReadBuf = 0xAA
        ppu.write(ppu.vRAMAddr, Byte(0x12))
        ppu.registers[0][2] = true

        let _: Byte = cpu.read(.ppuData)
        XCTAssertEqual(ppu.vRAMAddr, 0x00020)
    }
    
    func testCPUwritePPUData() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        
        guard let cpu = cpu, let ppu = ppu else { return }
        
        ppu.registers[0][2] = false
        cpu.write(.ppuData, Byte(0x12))
        XCTAssertEqual(ppu.vRAMAddr, 0x0001)
        
        ppu.registers[0][2] = true
        cpu.write(.ppuData, Byte(0x12))
        XCTAssertEqual(ppu.vRAMAddr, 0x0021)
    }
    
    func testOAMData() {
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ppu)
        XCTAssertNotNil(dma)
        
        guard let cpu = cpu, let ppu = ppu, let dma = dma else { return }

        for i in 0x0400..<0x0500 {
            cpu.write(Address(i), Byte(0x34))
        }
        cpu.write(.oamDMA, Byte(0x04))
        
        XCTAssertEqual(dma.ramAddr, 0x0400)
        XCTAssertTrue(dma.isProcessing)
        
        dma.runDMA()
        
        for i in 0x0400..<0x0500 {
            let ppuVal: Byte = ppu.spriteRAM.read(Address(i - 0x0400))
            let cpuVal: Byte = cpu.read(Address(i))
            XCTAssertEqual(ppuVal, cpuVal)
        }
    }
}
