//
//  PreferencesDataModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/7.
//

import Foundation
import RxCocoa
import RxSwift

protocol UserDefaultsStorable {
    func toStorable() -> Any
    static func fromStorable(_ value: Any) -> Self?
}

@propertyWrapper
struct UserDefaultsRelay<T> {
    private let key: String
    private let defaultValue: T
    private let relay: BehaviorRelay<T>
    private let disposeBag = DisposeBag()

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue

        // 从 UserDefaults 读取值，如果不存在则使用默认值
        let savedValue: T

        if let storable = defaultValue as? (any UserDefaultsStorable) {
            // 使用类型擦除方式访问协议实例
            let valueType = type(of: storable)
            if let storageValue = UserDefaults.standard.object(forKey: key),
               let value = valueType.fromStorable(storageValue) as? T {
                savedValue = value
            } else {
                savedValue = defaultValue
            }
        } else {
            // 标准类型直接使用
            savedValue = UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }

        relay = BehaviorRelay<T>(value: savedValue)

        // 观察变化并保存到 UserDefaults
        relay
            .skip(1) // 跳过初始值
            .subscribe(onNext: { value in
                if let storable = value as? any UserDefaultsStorable {
                    // 使用协议方法转换为可存储类型
                    UserDefaults.standard.set(storable.toStorable(), forKey: key)
                } else {
                    // 标准类型直接存储
                    UserDefaults.standard.set(value, forKey: key)
                }
            })
            .disposed(by: disposeBag)

        #if DEBUG
            _ = relay.subscribe {
                debugPrint("UserDefaultsRelay: \(key) changed to \($0)")
            }
        #endif
    }

    var wrappedValue: BehaviorRelay<T> {
        return relay
    }
}

class PreferencesDataModel {
    public static let shared = PreferencesDataModel()

    @UserDefaultsRelay("isEnabled", defaultValue: false)
    var isEnabled: BehaviorRelay<Bool>

    @UserDefaultsRelay("sendInterval", defaultValue: SendInterval.tenSeconds)
    var sendInterval: BehaviorRelay<SendInterval>
    
    @UserDefaultsRelay("focusReport", defaultValue: true)
    var focusReport: BehaviorRelay<Bool>
        
}

extension SendInterval: UserDefaultsStorable {
    func toStorable() -> Any {
        return rawValue
    }

    static func fromStorable(_ value: Any) -> SendInterval? {
        if let intValue = value as? Int {
            return SendInterval(rawValue: intValue)
        }
        return nil
    }
}

enum SendInterval: Int, CaseIterable {
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60

    func toString() -> String {
        switch self {
        case .tenSeconds:
            return "10s"
        case .thirtySeconds:
            return "30s"
        case .oneMinute:
            return "60s"
        }
    }

    static func toLabels() -> [String] {
        return SendInterval.allCases.map { $0.toString() }
    }

    static func labelToValue(_ label: String) -> SendInterval? {
        return SendInterval.allCases.first { $0.toString() == label }
    }
}
