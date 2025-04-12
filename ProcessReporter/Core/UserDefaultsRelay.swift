import Foundation
import RxCocoa
//
//  UserDefaultsRelay.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//
import RxSwift

protocol UserDefaultsStorable {
    func toStorable() -> Any?
    static func fromStorable(_ value: Any?) -> Self?
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
                let value = valueType.fromStorable(storageValue) as? T
            {
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
            .skip(1)  // 跳过初始值
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

protocol UserDefaultsJSONStorable: UserDefaultsStorable, Codable {}

extension UserDefaultsJSONStorable {
    func toStorable() -> Any? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        if let jsonData = try? encoder.encode(self) {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString ?? ""
        }
        return nil
    }

    static func fromStorable(_ value: Any?) -> Self? {
        guard let value = value as? String else {
            return nil
        }
        let decoder = JSONDecoder()
        if let jsonData = value.data(using: .utf8) {
            return try? decoder.decode(Self.self, from: jsonData)
        }
        return nil
    }
}
