import Foundation

extension UInt8 {
    mutating func set(bit: Int, _ value: Bool) {
        precondition(0 <= bit && bit <= 7)
        
        let mask = UInt8(1 << bit)
        
        if value {
            self |= mask
        } else {
            self &= ~mask
        }
    }
    
    func get(bit: Int) -> Bool {
        precondition(0 <= bit && bit <= 7)
        
        let mask = UInt8(1 << bit)
        
        return (self & mask) != 0
    }
    
    subscript(bit: Int) -> Bool {
        get {
            return get(bit: bit)
        }
        set(value) {
            set(bit: bit, value)
        }
    }
}
