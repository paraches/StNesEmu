//
//  StNesEmuTests.swift
//  StNesEmuTests
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import XCTest
@testable import StNesEmu

class StNesEmuTests: XCTestCase {
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
        
        let characterMem = RAM(memory: [UInt8](repeating: 0x1A, count: 0x4000)) // Create 16K RAM
        for i in 0..<cartridge.characterROM.size() {
            let byteData: Byte = cartridge.characterROM.read(i)
            characterMem.write(i, byteData)
        }
        let ppuBus = PPU_BUS(characterRAM: characterMem)
        let interrupts = Interrupts()
        
        let ppu = PPU(bus: ppuBus, interrupts: interrupts, config: PPU.PPUConfig(isHorizontalMirror: false))
        self.ppu = ppu
        
        let wRam = RAM(memory: [UInt8](repeating: 0x1A, count: 0x2000))
        let dma = DMA(ram: wRam, ppu: ppu)
        let cpubus = CPU_BUS(ram: wRam, programROM: RAM(memory: [UInt8](repeating: 0x1A, count: 0x8000)), ppu: ppu, dma: dma)
        cpu = CPU(bus: cpubus, interrupts: interrupts)
        cpu?.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReset() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.reset()
        XCTAssertEqual(cpu.P, 0x24)
        XCTAssertEqual(cpu.PC, 0x1A1A)
        XCTAssertEqual(cpu.SP, 0xFD)
        XCTAssertEqual(cpu.A, 0x00)
        XCTAssertEqual(cpu.X, 0x00)
        XCTAssertEqual(cpu.Y, 0x00)
    }
    
    //
    //  CPU
    //
    func testFetch() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x0200
        let code: Byte = cpu.fetch(0x0200)
        XCTAssertEqual(code, 0x1A)
        XCTAssertEqual(cpu.PC, 0x0201)
    }
    
    func testFetchWord() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x0200
        cpu.bus.ram.write(0x0201, Byte(0x56))
        let code: Word = cpu.fetchWord(0x0200)
        XCTAssertEqual(code, 0x561A)
        XCTAssertEqual(cpu.PC, 0x0202)
    }
    
    func testPush() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.push(0x56)
        let v1: Byte = cpu.read(0x01FD)
        XCTAssertEqual(cpu.SP, 0xFC)
        XCTAssertEqual(v1, 0x56)
        
        cpu.SP = 0x00
        cpu.push(0x56)
        let v2: Byte = cpu.read(0x0100)
        XCTAssertEqual(cpu.SP, 0xFF)
        XCTAssertEqual(v2, 0x56)
    }
    
    func testPop() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.bus.write(0x01FE, Byte(0x56))
        let v1 = cpu.pop()
        XCTAssertEqual(v1, 0x56)
        XCTAssertEqual(cpu.SP, 0xFE)
        
        cpu.SP = 0xFF
        cpu.bus.ram.write(0x0100, Byte(0x56))
        let v2 = cpu.pop()
        XCTAssertEqual(v2, 0x56)
        XCTAssertEqual(cpu.SP, 0x00)
    }
    
    func testStep() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x0200
        let cycle = cpu.run()
        XCTAssertEqual(cpu.PC, 0x0201)
        XCTAssertEqual(cycle, 2)
    }
    
    //
    //  Instructions
    //
    func testLDA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.execInstruction("LDA", 0x5F, .immediate)
        XCTAssertEqual(cpu.A, 0x5F)
        
        cpu.execInstruction("LDA", 0x6F, .zeroPage)
        XCTAssertEqual(cpu.A, 0x1A)
    }
    
    func testLDX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.execInstruction("LDX", 0x5F, .immediate)
        XCTAssertEqual(cpu.X, 0x5F)
        
        cpu.execInstruction("LDX", 0x6F, .zeroPage)
        XCTAssertEqual(cpu.X, 0x1A)
    }

    func testLDY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.execInstruction("LDY", 0x5F, .immediate)
        XCTAssertEqual(cpu.Y, 0x5F)
        
        cpu.execInstruction("LDY", 0x6F, .zeroPage)
        XCTAssertEqual(cpu.Y, 0x1A)
    }
    
    func testSTA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x12
        cpu.execInstruction("STA", 0x1234, .absolute)
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x12)
    }

    func testSTX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.X = 0x12
        cpu.execInstruction("STX", 0x1234, .absolute)
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x12)
    }

    func testSTY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.Y = 0x12
        cpu.execInstruction("STY", 0x1234, .absolute)
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x12)
    }
    
    func testTAX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x12
        cpu.execInstruction("TAX", 0x00, .implied)
        XCTAssertEqual(cpu.X, 0x12)
    }
    
    func testTAY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x12
        cpu.execInstruction("TAY", 0x00, .implied)
        XCTAssertEqual(cpu.Y, 0x12)
    }
    
    func testTSX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.SP = 0x12
        cpu.execInstruction("TSX", 0x00, .implied)
        XCTAssertEqual(cpu.X, 0x12)
    }
    
    func testTXA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.X = 0x12
        cpu.execInstruction("TXA", 0x00, .implied)
        XCTAssertEqual(cpu.A, 0x12)
    }
    
    func testTXS()  {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.X = 0x12
        cpu.execInstruction("TXS", 0x00, .implied)
        XCTAssertEqual(cpu.SP, 0x12)
    }
    
    func testTYA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.Y = 0x12
        cpu.execInstruction("TYA", 0x00, .immediate)
        XCTAssertEqual(cpu.A, 0x12)
    }

    func testADC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  check std adc
        cpu.A = 0x12
        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x13, .immediate)
        XCTAssertEqual(cpu.A, 0x25)

        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x13, .zeroPage)
        XCTAssertEqual(cpu.A, 0x3F)
        
        //  check carry flag
        cpu.A = 0x00
        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x10, .immediate)
        XCTAssertEqual(cpu.A, 0x10)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        cpu.A = 0xF0
        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x20, .immediate)
        XCTAssertEqual(cpu.A, 0x10)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])

        //  check overflow flag
        cpu.A = 0x40
        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x20, .immediate)
        XCTAssertEqual(cpu.A, 0x60)
        XCTAssertFalse(cpu.P[CPU.F.OVERFLOW])
        
        cpu.A = 0x40
        cpu.P[CPU.F.CARRY] = false
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("ADC", 0x40, .immediate)
        XCTAssertEqual(cpu.A, 0x80)
        XCTAssertTrue(cpu.P[CPU.F.OVERFLOW])
    }

    func testAND() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0xF5
        cpu.execInstruction("AND", 0x5F, .immediate)
        XCTAssertEqual(cpu.A, 0x55)
        
        cpu.A = 0xF7
        cpu.execInstruction("AND", 0x12, .zeroPage)
        XCTAssertEqual(cpu.A, 0x12)
    }
    
    func testALS() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x40
        cpu.execInstruction("ASL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x80)
        
        cpu.A = 0x81
        cpu.P[CPU.F.CARRY] = false
        cpu.execInstruction("ASL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x02)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.A = 0x41
        cpu.P[CPU.F.CARRY] = false
        cpu.execInstruction("ASL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x82)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        cpu.write(0x1234, Byte(0x40))
        cpu.execInstruction("ASL", 0x1234, .absolute)
        let v1: Byte = cpu.read(0x1234)
        XCTAssertEqual(v1, 0x80)

        cpu.write(0x1234, Byte(0x81))
        cpu.execInstruction("ASL", 0x1234, .absolute)
        let v2: Byte = cpu.read(0x1234)
        XCTAssertEqual(v2, 0x02)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x41))
        cpu.execInstruction("ASL", 0x1234, .absolute)
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x82)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
    }
    
    func testBIT() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  Zero flag
        cpu.write(0x1000, Byte(0x0F))
        cpu.A = 0xF0
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertTrue(cpu.P[CPU.F.ZERO])
        
        cpu.write(0x1000, Byte(0xFF))
        cpu.A = 0xF0
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertFalse(cpu.P[CPU.F.ZERO])
        
        //  Overflow Flag
        cpu.write(0x1000, Byte(0x40))
        cpu.A = 0x00
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertTrue(cpu.P[CPU.F.OVERFLOW])

        cpu.write(0x1000, Byte(0x00))
        cpu.A = 0x00
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertFalse(cpu.P[CPU.F.OVERFLOW])
        
        //  Negative flag
        cpu.write(0x1000, Byte(0x80))
        cpu.A = 0x00
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertTrue(cpu.P[CPU.F.NEGATIVE])
        
        cpu.write(0x1000, Byte(0x00))
        cpu.A = 0x00
        cpu.execInstruction("BIT", 0x1000, .absolute)
        XCTAssertFalse(cpu.P[CPU.F.NEGATIVE])
    }
    
    func testCMP() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  Carry Flag
        cpu.A = 0x02
        cpu.execInstruction("CMP", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.A = 0x01
        cpu.execInstruction("CMP", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        //  Zero flag
        cpu.A = 0x01
        cpu.execInstruction("CMP", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.ZERO])
        
        cpu.A = 0x02
        cpu.execInstruction("CMP", 0x01, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.ZERO])
        
        //  Negative Flag
        cpu.A = 0x81
        cpu.execInstruction("CMP", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.NEGATIVE])
        
        cpu.A = 0x81
        cpu.execInstruction("CMP", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.NEGATIVE])
    }
    
    func testCPX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  Carry Flag
        cpu.X = 0x02
        cpu.execInstruction("CPX", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.X = 0x01
        cpu.execInstruction("CPX", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        //  Zero flag
        cpu.X = 0x01
        cpu.execInstruction("CPX", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.ZERO])
        
        cpu.X = 0x02
        cpu.execInstruction("CPX", 0x01, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.ZERO])
        
        //  Negative Flag
        cpu.X = 0x81
        cpu.execInstruction("CPX", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.NEGATIVE])
        
        cpu.X = 0x81
        cpu.execInstruction("CPX", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.NEGATIVE])

    }

    func testCPY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  Carry Flag
        cpu.Y = 0x02
        cpu.execInstruction("CPY", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.Y = 0x01
        cpu.execInstruction("CPY", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        //  Zero flag
        cpu.Y = 0x01
        cpu.execInstruction("CPY", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.ZERO])
        
        cpu.Y = 0x02
        cpu.execInstruction("CPY", 0x01, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.ZERO])
        
        //  Negative Flag
        cpu.Y = 0x81
        cpu.execInstruction("CPY", 0x01, .immediate)
        XCTAssertTrue(cpu.P[CPU.F.NEGATIVE])
        
        cpu.Y = 0x81
        cpu.execInstruction("CPY", 0x02, .immediate)
        XCTAssertFalse(cpu.P[CPU.F.NEGATIVE])
        
    }

    func testDEC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x1234, Byte(0x10))
        cpu.execInstruction("DEC", 0x1234, .absolute)
        let v1: Byte = cpu.read(0x1234)
        XCTAssertEqual(v1, 0x0F)
    }
    
    func testDEX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.X = 0x10
        cpu.execInstruction("DEX", 0x00, .implied)
        XCTAssertEqual(cpu.X, 0x0F)
    }
    
    func testDEY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.Y = 0x10
        cpu.execInstruction("DEY", 0x00, .implied)
        XCTAssertEqual(cpu.Y, 0x0F)
    }
    
    func testEOR() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0xF5
        cpu.execInstruction("EOR", 0x5F, .immediate)
        XCTAssertEqual(cpu.A, 0xAA)
    }
    
    func testINC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x1234, Byte(0x10))
        cpu.execInstruction("INC", 0x1234, .absolute)
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x11)
    }

    func testINX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.X = 0x10
        cpu.execInstruction("INX", 0x00, .implied)
        XCTAssertEqual(cpu.X, 0x11)
    }

    func testINY() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.Y = 0x10
        cpu.execInstruction("INY", 0x00, .implied)
        XCTAssertEqual(cpu.Y, 0x11)
    }
    
    func testLSR() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        //  accumulator
        cpu.A = 0x40
        cpu.execInstruction("LSR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x20)
        
        cpu.A = 0x81
        cpu.execInstruction("LSR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x40)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.P[CPU.F.CARRY] = false
        cpu.A = 0x80
        cpu.execInstruction("LSR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x40)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        //  absolute
        cpu.write(0x1234, Byte(0x40))
        cpu.execInstruction("LSR", 0x1234, .absolute)
        let v1: Byte = cpu.read(0x1234)
        XCTAssertEqual(v1, 0x20)
        
        cpu.write(0x1234, Byte(0x81))
        cpu.execInstruction("LSR", 0x1234, .absolute)
        let v2: Byte = cpu.read(0x1234)
        XCTAssertEqual(v2, 0x40)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x80))
        cpu.execInstruction("LSR", 0x1234, .absolute)
        let v3: Byte = cpu.read(0x1234)
        XCTAssertEqual(v3, 0x40)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
    }
    
    func testORA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x01
        cpu.execInstruction("ORA", 0xF0, .immediate)
        XCTAssertEqual(cpu.A, 0xF1)
        
        cpu.A = 0x01
        cpu.write(0x1234, Byte(0xF0))
        cpu.execInstruction("ORA", 0x1234, .absolute)
        XCTAssertEqual(cpu.A, 0xF1)
    }
    
    func testROL() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x40
        cpu.execInstruction("ROL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x81)
        
        cpu.P[CPU.F.CARRY] = false
        cpu.A = 0x81
        cpu.execInstruction("ROL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x02)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.P[CPU.F.CARRY] = false
        cpu.A = 0x01
        cpu.execInstruction("ROL", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x02)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
        
        cpu.P[CPU.F.CARRY] = true
        cpu.write(0x1234, Byte(0x40))
        cpu.execInstruction("ROL", 0x1234, .absolute)
        let v1: Byte = cpu.read(0x1234)
        XCTAssertEqual(v1, 0x81)
        
        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x81))
        cpu.execInstruction("ROL", 0x1234, .absolute)
        let v2: Byte = cpu.read(0x1234)
        XCTAssertEqual(v2, 0x02)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x01))
        cpu.execInstruction("ROL", 0x1234, .absolute)
        let v3: Byte = cpu.read(0x1234)
        XCTAssertEqual(v3, 0x02)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
    }
    
    func testROR() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x04
        cpu.execInstruction("ROR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x82)

        cpu.P[CPU.F.CARRY] = false
        cpu.A = 0x81
        cpu.execInstruction("ROR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x40)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = false
        cpu.A = 0x80
        cpu.execInstruction("ROR", 0x00, .accumulator)
        XCTAssertEqual(cpu.A, 0x40)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = true
        cpu.write(0x1234, Byte(0x04))
        cpu.execInstruction("ROR", 0x1234, .absolute)
        let v1: Byte = cpu.read(0x1234)
        XCTAssertEqual(v1, 0x82)
        
        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x81))
        cpu.execInstruction("ROR", 0x1234, .absolute)
        let v2: Byte = cpu.read(0x1234)
        XCTAssertEqual(v2, 0x40)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
        
        cpu.P[CPU.F.CARRY] = false
        cpu.write(0x1234, Byte(0x80))
        cpu.execInstruction("ROR", 0x1234, .absolute)
        let v3: Byte = cpu.read(0x1234)
        XCTAssertEqual(v3, 0x40)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
    }
    
    func testSBC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x50
        cpu.execInstruction("SBC", 0xF0, .immediate)
        XCTAssertEqual(cpu.A, 0x60)
        
        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x50
        cpu.execInstruction("SBC", 0x70, .immediate)
        XCTAssertEqual(cpu.A, 0xE0)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x50
        cpu.execInstruction("SBC", 0x30, .immediate)
        XCTAssertEqual(cpu.A, 0x20)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])

        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x50
        cpu.execInstruction("SBC", 0xF0, .immediate)
        XCTAssertEqual(cpu.A, 0x60)
        XCTAssertFalse(cpu.P[CPU.F.OVERFLOW])
        
        cpu.P[CPU.F.CARRY] = true
        cpu.A = 0x50
        cpu.execInstruction("SBC", 0xB0, .immediate)
        XCTAssertEqual(cpu.A, 0xA0)
        XCTAssertTrue(cpu.P[CPU.F.OVERFLOW])
    }
    
    func testPHA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.A = 0x24
        cpu.execInstruction("PHA", 0x00, .implied)
        let v: Byte = cpu.read(0x0100 | Address(cpu.SP + 1))
        XCTAssertEqual(v, 0x24)
    }
    
    func testPHP() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P = 0x34
        cpu.execInstruction("PHP", 0x00, .implied)
        let v: Byte = cpu.read(0x0100 | Address(cpu.SP + 1))
        XCTAssertEqual(v, 0x34)

    }
    
    func testPLA() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x0100 | Address(cpu.SP &+ 1), Byte(0x24))
        cpu.execInstruction("PLA", 0x00, .implied)
        XCTAssertEqual(cpu.A, 0x24)
    }
    
    func testPLP() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x0100 | Address(cpu.SP &+ 1), Byte(0x24))
        cpu.execInstruction("PLP", 0x00, .implied)
        XCTAssertEqual(cpu.P, 0x24)
    }
    
    func testJMP() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0
        cpu.execInstruction("JMP", 0x1234, .indirectAbsolute)
        XCTAssertEqual(cpu.PC, 0x1234)
    }
    
    func testJSR() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x6543
        cpu.execInstruction("JSR", 0x1234, .relative)
        
        let adrs: Address = cpu.read(0x0100 | Address(cpu.SP + 1))
        XCTAssertEqual(adrs, 0x6542)
        
        XCTAssertEqual(cpu.PC, 0x1234)
    }
    
    func testRTS() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x0100 | Address(cpu.SP - 1), Word(0x1233))
        cpu.SP = cpu.SP &- 2
        cpu.execInstruction("RTS", 0x00, .implied)
        XCTAssertEqual(cpu.PC, 0x1234)
    }
    
    func testRTI() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0xABBA
        cpu.P = 0x24
        cpu.write(0xFFFE, Address(0x1234))
        
        cpu.execInstruction("BRK", 0x00, .implied)
        
        cpu.PC = 0x1234
        cpu.P = 0xFF
        
        cpu.execInstruction("RTI", 0x00, .implied)
        
        XCTAssertEqual(cpu.PC, 0xABBB)
        XCTAssertEqual(cpu.P, 0x24)
    }
    
    func testBCC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.CARRY] = true
        cpu.execInstruction("BCC", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.CARRY] = false
        cpu.execInstruction("BCC", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
    }
    
    func testBCS() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.CARRY] = true
        cpu.execInstruction("BCS", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.CARRY] = false
        cpu.execInstruction("BCS", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
    }
    
    func testBEQ() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.ZERO] = true
        cpu.execInstruction("BEQ", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.ZERO] = false
        cpu.execInstruction("BEQ", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
    }
    
    func testBNE() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.ZERO] = true
        cpu.execInstruction("BNE", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.ZERO] = false
        cpu.execInstruction("BNE", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
    }
    
    func testBMI() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.NEGATIVE] = true
        cpu.execInstruction("BMI", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.NEGATIVE] = false
        cpu.execInstruction("BMI", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
    }
    
    func testBPL() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.NEGATIVE] = true
        cpu.execInstruction("BPL", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.NEGATIVE] = false
        cpu.execInstruction("BPL", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
    }
    
    func testBVS() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.OVERFLOW] = true
        cpu.execInstruction("BVS", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("BVS", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)

    }
    
    func testBVC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x4000
        
        cpu.P[CPU.F.OVERFLOW] = true
        cpu.execInstruction("BVC", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x4000)
        
        cpu.PC = 0x4000
        
        cpu.P[CPU.F.OVERFLOW] = false
        cpu.execInstruction("BVC", calcRelative(0xF0, cpu.PC), .relative)
        XCTAssertEqual(cpu.PC, 0x3FF0)
    }
    
    func testCLC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.CARRY] = true
        cpu.execInstruction("CLC", 0x00, .implied)
        XCTAssertFalse(cpu.P[CPU.F.CARRY])
    }
    
    func testCLD() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.DECIMAL] = true
        cpu.execInstruction("CLD", 0x00, .implied)
        XCTAssertFalse(cpu.P[CPU.F.DECIMAL])
    }
    
    func testCLI() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.INTERRUPT] = true
        cpu.execInstruction("CLI", 0x00, .implied)
        XCTAssertFalse(cpu.P[CPU.F.INTERRUPT])
    }
    
    func testCLV() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.OVERFLOW] = true
        cpu.execInstruction("CLV", 0x00, .implied)
        XCTAssertFalse(cpu.P[CPU.F.OVERFLOW])
    }
    
    func testSEC() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.CARRY] = false
        cpu.execInstruction("SEC", 0x00, .implied)
        XCTAssertTrue(cpu.P[CPU.F.CARRY])
    }
    
    func testSED() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.DECIMAL] = false
        cpu.execInstruction("SED", 0x00, .implied)
        XCTAssertTrue(cpu.P[CPU.F.DECIMAL])
    }
    
    func testSEI() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P[CPU.F.INTERRUPT] = false
        cpu.execInstruction("SEI", 0x00, .implied)
        XCTAssertTrue(cpu.P[CPU.F.INTERRUPT])
    }
    
    func testBRK() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0xABBA
        cpu.P = 0x20
        cpu.write(0xFFFE, Word(0x1234))

        cpu.execInstruction("BRK", 0x1234, .absolute)
        
        let pc: Address = cpu.read(0x0100 | Address(cpu.SP &+ 2))
        XCTAssertEqual(pc, 0xABBB)
        
        let p: Byte = cpu.read(0x0100 | Address(cpu.SP &+ 1))
        XCTAssertEqual(p, 0x30)
        
        XCTAssertEqual(cpu.PC, 0x1234)
    }
    
    func testNOP() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.PC = 0x1234
        cpu.P = 0x24
        cpu.SP = 0xFD
        
        cpu.execInstruction("NOP", 0x00, .implied)
        
        XCTAssertEqual(cpu.PC, 0x1234)
        XCTAssertEqual(cpu.P, 0x24)
        XCTAssertEqual(cpu.SP, 0xFD)
    }
    
//
//  Unofficial instruction
//
    func testLAX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.write(0x1234, Byte(0x56))
        
        cpu.execInstruction("LAX", 0x1234, .absolute)
        
        XCTAssertEqual(cpu.A, cpu.X)
        XCTAssertEqual(cpu.A, 0x56)
    }
    
    func testSAX() {
        XCTAssertNotNil(cpu)
        guard let cpu = cpu else { return }

        cpu.P = 0x24
        cpu.A = 0x78
        cpu.X = 0xFF
        
        cpu.execInstruction("SAX", 0x1234, .absolute)
        
        let v: Byte = cpu.read(0x1234)
        XCTAssertEqual(v, 0x78)
        XCTAssertEqual(cpu.P, 0x24)
    }

    func calcRelative(_ baseAddr: Byte, _ pc: Address) -> Address {
        let addr = baseAddr < 0x0080 ? Address(baseAddr) &+ pc : Address(baseAddr) &+ pc &- 256
        return addr
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
