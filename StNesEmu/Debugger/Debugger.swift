//
//  Debugger.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/20.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Debugger: NSObject {
    private static var stepLogs = [CPU.StepInfo]()
    
    static func addStep(_ step: CPU.StepInfo) {
        stepLogs.append(step)
    }
    
    static func lastStep() -> CPU.StepInfo? {
        return stepLogs.last
    }
}
