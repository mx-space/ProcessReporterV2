//
//  PreferencesIntegrationViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import SnapKit

enum IntegrationType: String, CaseIterable {
    case mxSpace = "Mix Space"
    case slack = "Slack"

    func nsImage() -> NSImage {
        switch self {
        case .mxSpace:
            return NSImage(named: "mx-space")!
        case .slack:
            return NSImage(named: "slack")!
        }
    }
}

class SidebarViewController: NSViewController {
    private lazy var tableView: NSTableView = {
        let table = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("IntegrationColumn"))
        column.title = "Integrations"
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .plain
        // 设置斑马条纹
        table.usesAlternatingRowBackgroundColors = true

        table.rowHeight = 40
        table.delegate = self
        table.dataSource = self
        return table
    }()

    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.documentView = tableView
        return scroll
    }()

    override func loadView() {
        view = NSView()
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension SidebarViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return IntegrationType.allCases.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int)
        -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("IntegrationCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        let integrationType = IntegrationType.allCases[row]

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier

            let imageView = NSImageView()
            imageView.imageScaling = .scaleProportionallyDown
            cell?.addSubview(imageView)

            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.drawsBackground = false
            textField.backgroundColor = .clear
            cell?.addSubview(textField)
            cell?.textField = textField

            imageView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(8)
                make.size.equalTo(32)
            }

            textField.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(imageView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-8)
            }
        }

        if let imageView = cell?.subviews.first as? NSImageView {
            imageView.image = integrationType.nsImage()
        }
        cell?.textField?.stringValue = integrationType.rawValue

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            let selectedType = IntegrationType.allCases[selectedRow]
            // 通知主视图控制器更新右侧内容
            NotificationCenter.default.post(
                name: .init("IntegrationSelectionChanged"),
                object: selectedType)
        }
    }
}

class PreferencesIntegrationViewController: NSViewController, SettingWindowProtocol {
    var frameSize: NSSize = NSSize(width: 600, height: 400)

    private lazy var splitViewController: NSSplitViewController = {
        let svc = NSSplitViewController()
        return svc
    }()

    private lazy var sidebarViewController: SidebarViewController = {
        SidebarViewController()
    }()

    private lazy var contentViewController: NSViewController = {
        let vc = NSViewController()
        vc.view = NSView()
        vc.view.wantsLayer = true
        return vc
    }()

    override func loadView() {
        view = NSView()

        addChild(splitViewController)
        view.addSubview(splitViewController.view)

        // 配置分栏布局
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.canCollapse = false
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 300

        let contentItem = NSSplitViewItem(viewController: contentViewController)

        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(contentItem)

        // 设置分栏视图约束
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            splitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 监听列表选择变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIntegrationSelection(_:)),
            name: .init("IntegrationSelectionChanged"),
            object: nil
        )
    }

    @objc private func handleIntegrationSelection(_ notification: Notification) {
        guard let integrationType = notification.object as? IntegrationType else { return }
        // 根据选择的类型更新右侧视图
        updateContentView(for: integrationType)
    }

    private func updateContentView(for type: IntegrationType) {
        // 这里可以根据不同的集成类型显示不同的配置视图
        // TODO: 实现具体的配置视图切换逻辑
    }
}
