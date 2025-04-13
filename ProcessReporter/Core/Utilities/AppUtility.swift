//
//  AppUtility.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import AppKit
import Foundation

/// 应用信息缓存结构
struct AppInfo {
    let bundleID: String
    let displayName: String
    let icon: NSImage
    let path: URL?
    
    init(bundleID: String, displayName: String, icon: NSImage, path: URL? = nil) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.icon = icon
        self.path = path
    }

    static func defaultInfo(for bundleID: String) -> AppInfo {
        let defaultIcon = NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
        return AppInfo(bundleID: bundleID, displayName: bundleID, icon: defaultIcon)
    }
}

/// 应用程序工具类，用于处理应用程序信息的获取和转换
class AppUtility {
    // 单例模式
    static let shared = AppUtility()

    // 应用信息缓存
    private var appInfoCache: [String: AppInfo] = [:]

    /// 根据 Bundle ID 获取应用信息
    /// - Parameter bundleID: 应用的 Bundle Identifier
    /// - Returns: 包含应用信息的 AppInfo 对象
    func getAppInfo(for bundleID: String) -> AppInfo {
        // 检查缓存
        if let cachedInfo = appInfoCache[bundleID] {
            return cachedInfo
        }

        // 默认值
        let defaultIcon = NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
        var displayName = bundleID
        var icon = defaultIcon
        var path: URL?

        // 尝试获取应用详细信息
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            // 获取应用名称
            let appName = (appURL.lastPathComponent as NSString).deletingPathExtension

            // 尝试从Info.plist获取更精确的显示名称
            if let bundle = Bundle(url: appURL) {
                if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                    displayName = bundleName
                } else if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                    displayName = bundleName
                } else {
                    displayName = appName
                }
            } else {
                displayName = appName
            }

            // 获取应用图标
            icon = NSWorkspace.shared.icon(forFile: appURL.path)
            path = appURL
        }

        let appInfo = AppInfo(bundleID: bundleID, displayName: displayName, icon: icon, path: path)
        appInfoCache[bundleID] = appInfo

        return appInfo
    }

    /// 根据应用名称查找 Bundle ID
    /// - Parameter appName: 应用显示名称
    /// - Returns: 如果找到，返回对应的 Bundle ID，否则返回 nil
    func getBundleID(for appName: String) -> String? {
        // 尝试通过应用名查找应用
        let fileManager = FileManager.default
        let applicationsDirectory = "/Applications"
        let appFiles = try? fileManager.contentsOfDirectory(atPath: applicationsDirectory)

        // 首先在主应用目录查找
        if let appFiles = appFiles {
            for appFile in appFiles {
                if appFile.hasSuffix(".app") {
                    let appNameWithoutExtension = (appFile as NSString).deletingPathExtension
                    if appNameWithoutExtension == appName {
                        let appURL = URL(fileURLWithPath: "\(applicationsDirectory)/\(appFile)")
                        if let bundle = Bundle(url: appURL),
                           let bundleID = bundle.bundleIdentifier
                        {
                            return bundleID
                        }
                    }
                }
            }
        }

        // 也可以尝试使用系统API查找
        let workspace = NSWorkspace.shared
        let installedApps = workspace.runningApplications
        for app in installedApps {
            if app.localizedName == appName, let bundleID = app.bundleIdentifier {
                return bundleID
            }
        }

        return nil
    }

    /// 清除缓存
    func clearCache() {
        appInfoCache.removeAll()
    }
}
