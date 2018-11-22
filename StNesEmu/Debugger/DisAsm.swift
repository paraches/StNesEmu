//
//  DisAsm.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/19.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class DisAsm: NSObject {
    private static let DisAsmStrWidth = 15 + 4  //  15 col + 4 space
    private static let operandStringFormat: Dictionary<CPU.AddressingMode, String> = [
        .implied: "", .accumulator: "",
        .immediate: "#$%02X", .zeroPage: "$%02X", .relative: "$%02X", .zeroPageX: "$%02X, X", .zeroPageY: "$%02X, Y",
        .preIndexedIndirect:"($%02X, X)", .postIndexedIndirect: "($%02X), Y", .absolute: "$%02X%02X", .absoluteX: "$%02X%02X, X",
        .absoluteY: "$%02X%02X, Y", .indirectAbsolute: "($%02X%02X)"
    ]
    
    static func stepString(_ debugStep: CPU.StepInfo) -> String {
        guard let opcode = OpCode.opcodeTable[debugStep.opcode] else { return "Error: Unknown opcode \(debugStep.opcode.hexString())" }
        guard let baseName = opcode["baseName"] as? String else { return "Error: Can't find baseName" }
        guard let stringFormat = DisAsm.operandStringFormat[debugStep.mode] else { return "Error: Unknown mode \(debugStep.mode)" }
        
        switch debugStep.mode {
        case .accumulator, .implied:
            return DisAsm.alignDisAsmString(baseName)
        case .immediate, .zeroPage, .zeroPageX, .zeroPageY, .preIndexedIndirect, .postIndexedIndirect:
            let asmString = String(format: stringFormat, debugStep.operand.offset)
            return DisAsm.alignDisAsmString(baseName + " " + asmString)
        case .relative:
            let relativeString = String(format: stringFormat, debugStep.operand.offset)
            return DisAsm.alignDisAsmString(baseName + " " + relativeString + " = $" + debugStep.jump.hexString())
        case .absolute, .absoluteX, .absoluteY, .indirectAbsolute:
            let asmString = String(format: stringFormat, debugStep.operand.page, debugStep.operand.offset)
            return DisAsm.alignDisAsmString(baseName + " " + asmString)
        }
    }
    
    private static func alignDisAsmString(_ disAsmString: String) -> String {
        let spaceLength = DisAsmStrWidth - disAsmString.lengthOfBytes(using: .utf8)
        let spaceString = String(repeating: " ", count: spaceLength)
        return disAsmString + spaceString
    }
    
    static func addressAndCodeString(pc: Word, opcode: Byte, operand: Word, mode: CPU.AddressingMode) -> String {
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
        return "\(pc.hexString())  \(opcode.hexString()) \(operandLow) \(operandHigh)    "
    }

}
