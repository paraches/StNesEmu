//
//  CPU+Debugger.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/19.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension CPU {
    struct CPUState: CustomStringConvertible {
        let PC: Word
        let SP: Byte
        let A: Byte
        let X: Byte
        let Y: Byte
        let P: Byte

        var description: String {
            return "A:\(A.hexString()) X:\(X.hexString()) Y:\(Y.hexString()) P:\(P.hexString()) SP:\(SP.hexString())"
        }
    }
    
    struct StepInfo: CustomStringConvertible {
        let cpu: CPU.CPUState
        let opcode: Byte
        let operand: Word
        let mode: CPU.AddressingMode
        let jump: Word
        
        var description: String {
            let disAsmString = DisAsm.stepString(self)
            return codeString() + disAsmString + cpu.description
        }
        
        func codeString() -> String {
            var operandLow = ""
            var operandHigh = ""
            
            switch mode {
            case .accumulator, .implied:
                operandLow = "  "
                operandHigh = "  "
            case .immediate, .relative, .zeroPage, .zeroPageX, .zeroPageY, .preIndexedIndirect, .postIndexedIndirect:
                operandLow = operand.offset.hexString()
                operandHigh = "  "
            case .absolute, .absoluteX, .absoluteY, .indirectAbsolute:
                operandLow = operand.offset.hexString()
                operandHigh = operand.page.hexString()
            }
            return "\(cpu.PC.hexString())  \(opcode.hexString()) \(operandLow) \(operandHigh)    "
        }
    }

    func showStep(opcode: Byte, mode: AddressingMode, pc: Word) {
        let stepInfo = createStepInfo(opcode: opcode, mode: mode, pc: pc)
        print(stepInfo)
    }
    
    func createStepInfo(opcode: Byte, mode: AddressingMode, pc: Word) -> StepInfo {
        let operand = operandForMode(pc, mode)
        let jumpOffset = mode == .relative ? calcJumpOffset(Byte(operand)) : 0
        let stepInfo = StepInfo(cpu: CPUState(PC: pc, SP: SP, A: A, X: X, Y: Y, P: P),
                                opcode: opcode, operand: operand, mode: mode, jump: Address(Int(self.PC) + jumpOffset))
        return stepInfo
    }

    func operandForMode(_ PC: Address, _ mode: AddressingMode) -> Word {
        switch mode {
        case .absolute, .absoluteX, .absoluteY, .indirectAbsolute:
            return read(PC &+ 1)
        case .immediate, .relative, .zeroPage, .zeroPageX, .zeroPageY, .preIndexedIndirect, .postIndexedIndirect:
            let data: Byte = read(PC &+ 1)
            return Word(data)
        case .accumulator, .implied:
            return Word(0)
        }
    }

    func calcJumpOffset(_ offset: Byte) -> Int {
        return offset < 0x80 ? Int(offset) : Int(offset) - 256
    }
}
