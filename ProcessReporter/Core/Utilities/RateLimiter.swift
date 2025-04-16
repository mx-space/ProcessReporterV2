//
//  RateLimiter.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/16.
//
//
//  Ratelimiter.swift
//  ProcessReporter
//

import Foundation

class Ratelimiter {
    private let capacity: Int
    private let refillRate: Double // tokens per second
    private let minimumInterval: TimeInterval // 最小间隔时间
    private var tokens: Double
    private var lastRefillTimestamp: Date
    private var lastRequestTimestamp: Date?
    private let lock = NSLock()
    
    init(capacity: Int, refillRate: Double, minimumInterval: TimeInterval = 10) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.minimumInterval = minimumInterval
        self.tokens = Double(capacity)
        self.lastRefillTimestamp = Date()
    }
    
    func tryAcquire() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        
        // 检查最小间隔时间
        if let lastRequest = lastRequestTimestamp {
            let timeSinceLastRequest = now.timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumInterval {
                return false
            }
        }
        
        // 更新令牌数量
        let timePassed = now.timeIntervalSince(lastRefillTimestamp)
        tokens = min(Double(capacity), tokens + timePassed * refillRate)
        lastRefillTimestamp = now
        
        if tokens >= 1 {
            tokens -= 1
            lastRequestTimestamp = now
            return true
        }
        
        return false
    }
}
