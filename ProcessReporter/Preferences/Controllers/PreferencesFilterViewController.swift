//
//  PreferencesFilterViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//

import AppKit
import Foundation
import RxCocoa
import RxSwift
import SnapKit

class PreferencesFilterViewController: NSViewController, SettingWindowProtocol {
    final let frameSize: NSSize = .init(width: 600, height: 500)

    private let disposeBag = DisposeBag()

    // UI Components
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.automaticallyAdjustsContentInsets = false
        return scrollView
    }()

    private lazy var contentView: NSView = {
        let view = NSView()
        return view
    }()

    // Process Filter Section
    private lazy var processHeaderLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Process Filter")
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private lazy var processDescriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
            "Applications added to this list will be ignored when reporting processes.")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()

    // 表格相关属性
    private var processTableView: NSTableView!
    private var mediaTableView: NSTableView!

    private lazy var processTableContainer: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }()

    private lazy var processButtonStack: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        stackView.wantsLayer = true
        stackView.layer?.masksToBounds = true
        return stackView
    }()

    private lazy var addProcessButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")!,
            target: self, action: #selector(addProcess))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        return button
    }()

    private lazy var removeProcessButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove")!,
            target: self, action: #selector(removeSelectedProcesses))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        button.isEnabled = false
        return button
    }()

    // Media Filter Section
    private lazy var mediaHeaderLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Media Filter")
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private lazy var mediaDescriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Applications added to this list will be ignored when reporting media."
        )
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()

    private lazy var mediaTableContainer: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }()

    private lazy var mediaButtonStack: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        stackView.wantsLayer = true

        stackView.layer?.masksToBounds = true
        return stackView
    }()

    private lazy var addMediaButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")!,
            target: self, action: #selector(addMedia))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        return button
    }()

    private lazy var removeMediaButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove")!,
            target: self, action: #selector(removeSelectedMedia))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        button.isEnabled = false
        return button
    }()

    override func loadView() {
        view = NSView()

        // 在这里初始化表格，避免死循环
        setupTableViews()
        setupUI()
        bindData()
        setupDragAndDrop()
    }

    private func setupTableViews() {
        // 初始化进程表格
        processTableView = CustomTableView()
        processTableView.style = .sourceList
        processTableView.usesAlternatingRowBackgroundColors = true
        processTableView.rowHeight = 24
        processTableView.gridStyleMask = .solidHorizontalGridLineMask
        processTableView.backgroundColor = .controlBackgroundColor
        processTableView.gridColor = .separatorColor
        processTableView.intercellSpacing = NSSize(width: 3.0, height: 2.0)
        processTableView.menu = createContextMenu(for: .process)
        processTableView.autoresizingMask = [.width]
        processTableView.target = self
        processTableView.action = #selector(tableViewClicked(_:))
        processTableView.wantsLayer = true
        processTableView.layer?.borderWidth = 1
        processTableView.layer?.borderColor = NSColor.separatorColor.cgColor
        processTableView.layer?.cornerRadius = 8

        // 设置键盘处理
        (processTableView as? CustomTableView)?.keyActionHandler = self

        let processIconColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("ProcessIconColumn"))
        processIconColumn.width = 24
        processIconColumn.minWidth = 24
        processIconColumn.maxWidth = 24
        processIconColumn.isEditable = false

        let processNameColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("ProcessNameColumn"))
        processNameColumn.title = "Item"
        processNameColumn.minWidth = 150
        processNameColumn.isEditable = false
        processNameColumn.resizingMask = .autoresizingMask

        let processKindColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("ProcessKindColumn"))
        processKindColumn.title = "Kind"
        processKindColumn.width = 100
        processKindColumn.minWidth = 80
        processKindColumn.maxWidth = 100
        processKindColumn.isEditable = false

        processTableView.addTableColumn(processIconColumn)
        processTableView.addTableColumn(processNameColumn)
        processTableView.addTableColumn(processKindColumn)

        // 设置列自动调整宽度
        processTableView.sizeLastColumnToFit()
        processTableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle

        processTableView.dataSource = self
        processTableView.delegate = self
        processTableView.allowsMultipleSelection = true
        processTableView.headerView = nil

        // 初始化媒体表格
        mediaTableView = CustomTableView()
        processTableView.style = .sourceList
        mediaTableView.usesAlternatingRowBackgroundColors = true
        mediaTableView.rowHeight = 24
        mediaTableView.gridStyleMask = .solidHorizontalGridLineMask
        mediaTableView.backgroundColor = .controlBackgroundColor
        mediaTableView.gridColor = .separatorColor
        mediaTableView.intercellSpacing = NSSize(width: 3.0, height: 2.0)
        mediaTableView.menu = createContextMenu(for: .media)
        mediaTableView.autoresizingMask = [.width]
        mediaTableView.target = self
        mediaTableView.action = #selector(tableViewClicked(_:))
        // 设置键盘处理
        (mediaTableView as? CustomTableView)?.keyActionHandler = self
        mediaTableView.wantsLayer = true
        mediaTableView.layer?.borderWidth = 1
        mediaTableView.layer?.borderColor = NSColor.separatorColor.cgColor
        mediaTableView.layer?.cornerRadius = 8

        let mediaIconColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("MediaIconColumn"))
        mediaIconColumn.width = 24
        mediaIconColumn.minWidth = 24
        mediaIconColumn.maxWidth = 24
        mediaIconColumn.isEditable = false

        let mediaNameColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("MediaNameColumn"))
        mediaNameColumn.title = "Item"
        mediaNameColumn.minWidth = 150
        mediaNameColumn.isEditable = false
        mediaNameColumn.resizingMask = .autoresizingMask

        let mediaKindColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("MediaKindColumn"))
        mediaKindColumn.title = "Kind"
        mediaKindColumn.width = 100
        mediaKindColumn.minWidth = 80
        mediaKindColumn.maxWidth = 100
        mediaKindColumn.isEditable = false

        mediaTableView.addTableColumn(mediaIconColumn)
        mediaTableView.addTableColumn(mediaNameColumn)
        mediaTableView.addTableColumn(mediaKindColumn)

        // 设置列自动调整宽度
        mediaTableView.sizeLastColumnToFit()
        mediaTableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle

        mediaTableView.dataSource = self
        mediaTableView.delegate = self
        mediaTableView.allowsMultipleSelection = true
        mediaTableView.headerView = nil

        // 设置文档视图
        processTableContainer.documentView = processTableView
        mediaTableContainer.documentView = mediaTableView

        // 确保表格适应容器宽度
        processTableView.frame.size.width = processTableContainer.contentSize.width - 10
        mediaTableView.frame.size.width = mediaTableContainer.contentSize.width - 10
    }

    private func setupDragAndDrop() {
        // 为进程表格设置拖拽类型
        processTableView.registerForDraggedTypes([.fileURL])
        processTableView.setDraggingSourceOperationMask(.copy, forLocal: false)

        // 为媒体表格设置拖拽类型
        mediaTableView.registerForDraggedTypes([.fileURL])
        mediaTableView.setDraggingSourceOperationMask(.copy, forLocal: false)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.documentView = contentView

        // Process Filter Section
        contentView.addSubview(processHeaderLabel)
        contentView.addSubview(processDescriptionLabel)
        contentView.addSubview(processTableContainer)
        contentView.addSubview(processButtonStack)

        processButtonStack.addArrangedSubview(addProcessButton)
        processButtonStack.addArrangedSubview(removeProcessButton)

        // Media Filter Section
        contentView.addSubview(mediaHeaderLabel)
        contentView.addSubview(mediaDescriptionLabel)
        contentView.addSubview(mediaTableContainer)
        contentView.addSubview(mediaButtonStack)

        mediaButtonStack.addArrangedSubview(addMediaButton)
        mediaButtonStack.addArrangedSubview(removeMediaButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Process Filter Section
        processHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(20)
        }

        processDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(processHeaderLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        processTableContainer.snp.makeConstraints { make in
            make.top.equalTo(processDescriptionLabel.snp.bottom).offset(10)
            make.width.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview().offset(20)
            make.height.equalTo(180)
        }

        processButtonStack.snp.makeConstraints { make in
            make.top.equalTo(processTableContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(45)
            make.height.equalTo(22)
        }

        // Media Filter Section
        mediaHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(processButtonStack.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
        }

        mediaDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaHeaderLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        mediaTableContainer.snp.makeConstraints { make in
            make.top.equalTo(mediaDescriptionLabel.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview().offset(20)
            make.width.equalToSuperview().inset(20)
            make.height.equalTo(180)
        }

        mediaButtonStack.snp.makeConstraints { make in
            make.top.equalTo(mediaTableContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(45)
            make.height.equalTo(22)
            make.bottom.equalToSuperview().inset(20)
        }

        addProcessButton.contentTintColor = .controlAccentColor
        removeProcessButton.contentTintColor = .controlAccentColor
        addMediaButton.contentTintColor = .controlAccentColor
        removeMediaButton.contentTintColor = .controlAccentColor
    }

    private func bindData() {
        PreferencesDataModel.filteredProcesses
            .subscribe(onNext: { [weak self] _ in
                self?.processTableView.reloadData()
            })
            .disposed(by: disposeBag)

        PreferencesDataModel.filteredMediaProcesses
            .subscribe(onNext: { [weak self] _ in
                self?.mediaTableView.reloadData()
            })
            .disposed(by: disposeBag)

        // 监听表格选择变化来启用/禁用删除按钮
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tableViewSelectionDidChange(_:)),
            name: NSTableView.selectionDidChangeNotification,
            object: nil)

        // 初始状态下禁用删除按钮
        removeProcessButton.isEnabled = false
        removeMediaButton.isEnabled = false
    }

    @objc func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }

        if tableView == processTableView {
            removeProcessButton.isEnabled = !tableView.selectedRowIndexes.isEmpty
        } else if tableView == mediaTableView {
            removeMediaButton.isEnabled = !tableView.selectedRowIndexes.isEmpty
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func addProcess() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose applications to filter from process reporting"

        panel.beginSheetModal(for: view.window!) { response in
            guard response == .OK else { return }

            var bundleIDs: [String] = []
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                    bundleIDs.append(bundleID)
                }
            }

            var currentProcesses = PreferencesDataModel.filteredProcesses.value
            for bundleID in bundleIDs {
                if !currentProcesses.contains(bundleID) {
                    currentProcesses.append(bundleID)
                }
            }
            PreferencesDataModel.filteredProcesses.accept(currentProcesses)
        }
    }

    @objc private func addMedia() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose applications to filter from media reporting"

        panel.beginSheetModal(for: view.window!) { response in
            guard response == .OK else { return }

            var bundleIDs: [String] = []
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                    bundleIDs.append(bundleID)
                }
            }

            var currentMedia = PreferencesDataModel.filteredMediaProcesses.value
            for bundleID in bundleIDs {
                if !currentMedia.contains(bundleID) {
                    currentMedia.append(bundleID)
                }
            }
            PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
        }
    }

    @objc private func removeSelectedProcesses() {
        let selectedRows = processTableView.selectedRowIndexes
        var currentProcesses = PreferencesDataModel.filteredProcesses.value

        let sortedIndexes = selectedRows.sorted(by: >)
        for index in sortedIndexes {
            if index < currentProcesses.count {
                currentProcesses.remove(at: index)
            }
        }

        PreferencesDataModel.filteredProcesses.accept(currentProcesses)
    }

    @objc private func removeSelectedMedia() {
        let selectedRows = mediaTableView.selectedRowIndexes
        var currentMedia = PreferencesDataModel.filteredMediaProcesses.value

        let sortedIndexes = selectedRows.sorted(by: >)
        for index in sortedIndexes {
            if index < currentMedia.count {
                currentMedia.remove(at: index)
            }
        }

        PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        adjustTableColumnsWidth()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        adjustTableColumnsWidth()

        // 确保表格宽度总是与容器宽度匹配
        processTableView.frame.size.width = processTableContainer.contentSize.width
        mediaTableView.frame.size.width = mediaTableContainer.contentSize.width
    }

    private func adjustTableColumnsWidth() {
        // 确保表格列宽度填充整个容器
        if let nameColumn = processTableView.tableColumn(
            withIdentifier: NSUserInterfaceItemIdentifier("ProcessNameColumn"))
        {
            let totalWidth = processTableContainer.contentSize.width
            let iconWidth =
                processTableView.tableColumn(
                    withIdentifier: NSUserInterfaceItemIdentifier("ProcessIconColumn"))?.width ?? 24
            let kindWidth =
                processTableView.tableColumn(
                    withIdentifier: NSUserInterfaceItemIdentifier("ProcessKindColumn"))?.width
                ?? 100

            // 减去其他列的宽度和间距
            nameColumn.width = totalWidth - iconWidth - kindWidth - 10
        }

        if let nameColumn = mediaTableView.tableColumn(
            withIdentifier: NSUserInterfaceItemIdentifier("MediaNameColumn"))
        {
            let totalWidth = mediaTableContainer.contentSize.width
            let iconWidth =
                mediaTableView.tableColumn(
                    withIdentifier: NSUserInterfaceItemIdentifier("MediaIconColumn"))?.width ?? 24
            let kindWidth =
                mediaTableView.tableColumn(
                    withIdentifier: NSUserInterfaceItemIdentifier("MediaKindColumn"))?.width ?? 100

            // 减去其他列的宽度和间距
            nameColumn.width = totalWidth - iconWidth - kindWidth - 10
        }
    }

    // MARK: - Context Menu

    private enum TableType {
        case process
        case media
    }

    private func createContextMenu(for tableType: TableType) -> NSMenu {
        let menu = NSMenu()

        // Set the menu delegate to handle the right-clicked row
        menu.delegate = self

        let removeItem = NSMenuItem(
            title: "Remove", action: #selector(contextMenuRemove(_:)), keyEquivalent: "")
        removeItem.target = self
        removeItem.tag = tableType == .process ? 0 : 1

        let openInFinderItem = NSMenuItem(
            title: "Open in Finder", action: #selector(contextMenuOpenInFinder(_:)),
            keyEquivalent: "")
        openInFinderItem.target = self
        openInFinderItem.tag = tableType == .process ? 0 : 1

        menu.addItem(removeItem)
        menu.addItem(openInFinderItem)

        return menu
    }

    @objc private func contextMenuRemove(_ sender: NSMenuItem) {
        let tableType = sender.tag

        if tableType == 0 {
            // Process table
            if !processTableView.selectedRowIndexes.isEmpty {
                // 如果有选中的行，优先删除已选择的项目
                removeSelectedProcesses()
            } else {
                // 如果没有选中的行，删除右键点击的项目
                guard let clickInfo = sender.representedObject as? [String: Any],
                      let row = clickInfo["row"] as? Int
                else {
                    return
                }

                var currentProcesses = PreferencesDataModel.filteredProcesses.value
                if row < currentProcesses.count {
                    currentProcesses.remove(at: row)
                    PreferencesDataModel.filteredProcesses.accept(currentProcesses)
                }
            }
        } else {
            // Media table
            if !mediaTableView.selectedRowIndexes.isEmpty {
                // 如果有选中的行，优先删除已选择的项目
                removeSelectedMedia()
            } else {
                // 如果没有选中的行，删除右键点击的项目
                guard let clickInfo = sender.representedObject as? [String: Any],
                      let row = clickInfo["row"] as? Int
                else {
                    return
                }

                var currentMedia = PreferencesDataModel.filteredMediaProcesses.value
                if row < currentMedia.count {
                    currentMedia.remove(at: row)
                    PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
                }
            }
        }
    }

    @objc private func contextMenuOpenInFinder(_ sender: NSMenuItem) {
        // Use the clicked row stored in the menu item's representedObject
        guard let clickInfo = sender.representedObject as? [String: Any],
              let row = clickInfo["row"] as? Int,
              let tableType = clickInfo["tableType"] as? Int
        else {
            return
        }

        var bundleID: String?

        if tableType == 0 {
            // Process table
            let processes = PreferencesDataModel.filteredProcesses.value
            if row < processes.count {
                bundleID = processes[row]
            }
        } else {
            // Media table
            let media = PreferencesDataModel.filteredMediaProcesses.value
            if row < media.count {
                bundleID = media[row]
            }
        }

        guard let bundleID = bundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        else {
            return
        }

        NSWorkspace.shared.selectFile(appURL.path, inFileViewerRootedAtPath: "")
    }

    // MARK: - Table Click Handling

    @objc private func tableViewClicked(_ sender: NSTableView) {
        // 获取当前鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        guard let window = view.window else { return }
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        let viewPoint = view.convert(windowPoint, from: nil)
        let tablePoint = sender.convert(viewPoint, from: view)

        // 检查点击的是否是表格行
        let clickedRow = sender.row(at: tablePoint)

        // 如果点击的不是表格行，取消所有选择
        if clickedRow == -1 {
            sender.deselectAll(nil)

            // 更新删除按钮状态
            if sender == processTableView {
                removeProcessButton.isEnabled = false
            } else if sender == mediaTableView {
                removeMediaButton.isEnabled = false
            }
        }
    }
}

// TableView DataSource & Delegate
extension PreferencesFilterViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == processTableView {
            return PreferencesDataModel.filteredProcesses.value.count
        } else if tableView == mediaTableView {
            return PreferencesDataModel.filteredMediaProcesses.value.count
        }
        return 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int)
        -> NSView?
    {
        guard let tableColumn = tableColumn else { return nil }

        var appBundleID: String?
        var appName: String?
        var appIcon: NSImage?

        if tableView == processTableView {
            let processes = PreferencesDataModel.filteredProcesses.value
            if row < processes.count {
                appBundleID = processes[row]
            }
        } else if tableView == mediaTableView {
            let media = PreferencesDataModel.filteredMediaProcesses.value
            if row < media.count {
                appBundleID = media[row]
            }
        }

        guard let bundleID = appBundleID else { return nil }

        // 获取应用名称和图标
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
            appName = (appURL.lastPathComponent as NSString).deletingPathExtension
        } else {
            appName = bundleID
            appIcon = NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        }

        // 创建单元格
        let cellView = NSTableCellView()
        cellView.wantsLayer = true
        cellView.layer?.backgroundColor = NSColor.clear.cgColor

        switch tableColumn.identifier.rawValue {
        case "ProcessIconColumn", "MediaIconColumn":
            let imageView = NSImageView()
            imageView.image = appIcon
            imageView.imageScaling = .scaleProportionallyDown
            cellView.addSubview(imageView)
            cellView.imageView = imageView

            imageView.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.size.equalTo(16)
            }

        case "ProcessNameColumn", "MediaNameColumn":
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.drawsBackground = false
            textField.backgroundColor = .clear
            textField.stringValue = appName ?? bundleID
            cellView.addSubview(textField)
            cellView.textField = textField

            textField.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(4)
                make.right.equalToSuperview().offset(-4)
            }

        case "ProcessKindColumn", "MediaKindColumn":
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.drawsBackground = false
            textField.backgroundColor = .clear
            textField.textColor = .secondaryLabelColor
            textField.stringValue = "Application"
            cellView.addSubview(textField)
            cellView.textField = textField

            textField.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(4)
                make.right.equalToSuperview().offset(-4)
            }

        default:
            break
        }

        return cellView
    }

    // 实现拖放支持
    func tableView(
        _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        // 检查拖放板中是否有应用文件
        if let urls = getAppURLsFromPasteboard(info.draggingPasteboard), !urls.isEmpty {
            // 允许在表格区域内拖放应用（包括空表）
            return .copy
        }
        return []
    }

    func tableView(
        _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        guard let urls = getAppURLsFromPasteboard(info.draggingPasteboard), !urls.isEmpty else {
            return false
        }

        var bundleIDs: [String] = []
        for url in urls {
            if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                bundleIDs.append(bundleID)
            }
        }

        if bundleIDs.isEmpty {
            return false
        }

        if tableView == processTableView {
            var currentProcesses = PreferencesDataModel.filteredProcesses.value
            for bundleID in bundleIDs {
                if !currentProcesses.contains(bundleID) {
                    currentProcesses.append(bundleID)
                }
            }
            PreferencesDataModel.filteredProcesses.accept(currentProcesses)
        } else if tableView == mediaTableView {
            var currentMedia = PreferencesDataModel.filteredMediaProcesses.value
            for bundleID in bundleIDs {
                if !currentMedia.contains(bundleID) {
                    currentMedia.append(bundleID)
                }
            }
            PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
        }

        return true
    }

    private func getAppURLsFromPasteboard(_ pasteboard: NSPasteboard) -> [URL]? {
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        else {
            return nil
        }

        return items.filter { $0.pathExtension.lowercased() == "app" }
    }
}

// MARK: - NSMenuDelegate

extension PreferencesFilterViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Get the location of the mouse click
        let mouseLocation = NSEvent.mouseLocation

        // Convert to window coordinates
        guard let window = view.window else { return }
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)

        // Convert to view coordinates
        let viewPoint = view.convert(windowPoint, from: nil)

        var tableView: NSTableView?
        var tableType: Int = -1

        // Determine which table view was clicked
        if processTableContainer.frame.contains(viewPoint) {
            tableView = processTableView
            tableType = 0
        } else if mediaTableContainer.frame.contains(viewPoint) {
            tableView = mediaTableView
            tableType = 1
        }

        guard let tableView = tableView else { return }

        // Convert to table view coordinates
        let tablePoint = tableView.convert(viewPoint, from: view)

        // Get the row that was clicked
        let row = tableView.row(at: tablePoint)
        if row >= 0 {
            // Store the row and table type in each menu item
            for item in menu.items {
                item.representedObject = ["row": row, "tableType": tableType]
            }
        } else {
            // Disable the menu items if no valid row was clicked
            for item in menu.items {
                item.isEnabled = false
            }
        }
    }
}

// MARK: - Custom TableView

private class CustomTableView: NSTableView {
    weak var keyActionHandler: CustomTableViewKeyHandler?

    override func mouseDown(with event: NSEvent) {
        // 获取鼠标点击位置
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)

        // 如果点击的是空白区域，取消所有选择
        if row == -1 {
            deselectAll(nil)
            // 通知外部更新按钮状态
            NotificationCenter.default.post(
                name: NSTableView.selectionDidChangeNotification,
                object: self)
        } else {
            // 否则调用默认处理
            super.mouseDown(with: event)
        }
    }

    // 处理键盘事件
    override func keyDown(with event: NSEvent) {
        // 检查是否是退格键 (backspace/delete)
        if event.keyCode == 51 || event.keyCode == 117 {
            // 如果有选中的行且有设置处理者
            if !selectedRowIndexes.isEmpty && keyActionHandler != nil {
                keyActionHandler?.handleDeleteKeyPress(in: self)
                return
            }
        }

        // 其他键默认处理
        super.keyDown(with: event)
    }
}

// 自定义表格视图键盘处理协议
protocol CustomTableViewKeyHandler: AnyObject {
    func handleDeleteKeyPress(in tableView: NSTableView)
}

// MARK: - CustomTableViewKeyHandler

extension PreferencesFilterViewController: CustomTableViewKeyHandler {
    func handleDeleteKeyPress(in tableView: NSTableView) {
        if tableView == processTableView {
            removeSelectedProcesses()
        } else if tableView == mediaTableView {
            removeSelectedMedia()
        }
    }
}
