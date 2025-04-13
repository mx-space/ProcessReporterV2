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

// MARK: - Constants

private enum FilterViewConstants {
    static let sectionTopOffset: CGFloat = 24
    static let descriptionTopOffset: CGFloat = 6
    static let descriptionSideInset: CGFloat = 20
    static let tableTopOffset: CGFloat = 10
    static let tableSideInset: CGFloat = 20
    static let tableHeight: CGFloat = 180
    static let buttonStackTopOffset: CGFloat = 8
    static let buttonStackWidth: CGFloat = 45
    static let buttonStackHeight: CGFloat = 22
    static let bottomInset: CGFloat = 20
    static let cornerRadius: CGFloat = 8
    static let borderWidth: CGFloat = 1
    static let iconColumnWidth: CGFloat = 24
    static let kindColumnWidth: CGFloat = 100
    static let kindColumnMinWidth: CGFloat = 80
    static let nameColumnMinWidth: CGFloat = 150
    static let cellTextSideInset: CGFloat = 4
    static let iconSize: CGFloat = 16
    static let headerHeight: CGFloat = 20  // 标题文本的大致高度
    static let descriptionHeight: CGFloat = 20  // 描述文本的大致高度
    static let sectionBottomPadding: CGFloat = 10  // 每个部分底部的额外内边距

    // 计算FilterTableView的固定总高度
    static var filterViewTotalHeight: CGFloat {
        return sectionTopOffset + headerHeight + descriptionTopOffset + descriptionHeight
            + tableTopOffset + tableHeight + buttonStackTopOffset + buttonStackHeight
            + sectionBottomPadding
    }
}

// MARK: - FilterTableView

class FilterTableView: NSView {
    enum FilterType {
        case process
        case media
    }

    // MARK: Properties

    private let disposeBag = DisposeBag()
    private let type: FilterType
    private var items = [String]()
    weak var delegate: FilterTableViewDelegate?

    // MARK: UI Components

    private lazy var headerLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: type == .process ? "Process Filter" : "Media Filter")
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private lazy var descriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: type == .process
                ? "Applications added to this list will be ignored when reporting processes."
                : "Applications added to this list will be ignored when reporting media."
        )
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()

    private lazy var tableContainer: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }()

    private lazy var tableView: CustomTableView = {
        let tableView = CustomTableView()
        tableView.style = .sourceList
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 24
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        tableView.backgroundColor = .controlBackgroundColor
        tableView.gridColor = .separatorColor
        tableView.intercellSpacing = NSSize(width: 3.0, height: 2.0)
        tableView.menu = createContextMenu()
        tableView.autoresizingMask = [.width]
        tableView.target = self
        tableView.action = #selector(tableViewClicked(_:))
        tableView.wantsLayer = true
        tableView.layer?.borderWidth = FilterViewConstants.borderWidth
        tableView.layer?.borderColor = NSColor.separatorColor.cgColor
        tableView.layer?.cornerRadius = FilterViewConstants.cornerRadius

        // 设置键盘处理
        tableView.keyActionHandler = self

        // 为表格设置拖拽类型
        tableView.registerForDraggedTypes([.fileURL])
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)

        return tableView
    }()

    private lazy var buttonStack: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        stackView.wantsLayer = true
        stackView.layer?.masksToBounds = true
        return stackView
    }()

    private lazy var addButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")!,
            target: self, action: #selector(addItem))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        button.contentTintColor = .controlAccentColor
        return button
    }()

    private lazy var removeButton: NSButton = {
        let button = NSButton(
            image: NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove")!,
            target: self, action: #selector(removeSelectedItems))
        button.bezelStyle = .texturedSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setButtonType(.momentaryPushIn)
        button.isEnabled = false
        button.contentTintColor = .controlAccentColor
        return button
    }()

    // MARK: Initialization

    init(type: FilterType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
        setupTableView()

        // 设置固定高度，防止自动扩展
        self.translatesAutoresizingMaskIntoConstraints = false

        // 监听表格选择变化来启用/禁用删除按钮
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tableViewSelectionDidChange(_:)),
            name: NSTableView.selectionDidChangeNotification,
            object: tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Setup

    private func setupUI() {
        addSubview(headerLabel)
        addSubview(descriptionLabel)
        addSubview(tableContainer)
        addSubview(buttonStack)

        buttonStack.addArrangedSubview(addButton)
        buttonStack.addArrangedSubview(removeButton)

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(FilterViewConstants.sectionTopOffset)
            make.left.equalToSuperview().offset(FilterViewConstants.descriptionSideInset)
            make.height.equalTo(FilterViewConstants.headerHeight)
            
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(
                FilterViewConstants.descriptionTopOffset)
            make.left.equalToSuperview().offset(FilterViewConstants.descriptionSideInset)
            make.right.equalToSuperview().offset(-FilterViewConstants.descriptionSideInset)
            make.height.equalTo(FilterViewConstants.descriptionHeight)
        }

        tableContainer.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(FilterViewConstants.tableTopOffset)
            make.horizontalEdges.equalToSuperview().inset(FilterViewConstants.tableSideInset)
            make.height.equalTo(FilterViewConstants.tableHeight)
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(tableContainer.snp.bottom).offset(
                FilterViewConstants.buttonStackTopOffset)
            make.left.equalToSuperview().offset(FilterViewConstants.tableSideInset)
            make.width.equalTo(FilterViewConstants.buttonStackWidth)
            make.height.equalTo(FilterViewConstants.buttonStackHeight)
            make.bottom.equalToSuperview().offset(FilterViewConstants.buttonStackTopOffset)
        }
    }

    private func setupTableView() {
        let iconColumnId = type == .process ? "ProcessIconColumn" : "MediaIconColumn"
        let nameColumnId = type == .process ? "ProcessNameColumn" : "MediaNameColumn"
        let kindColumnId = type == .process ? "ProcessKindColumn" : "MediaKindColumn"

        let iconColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(iconColumnId))
        iconColumn.width = FilterViewConstants.iconColumnWidth
        iconColumn.minWidth = FilterViewConstants.iconColumnWidth
        iconColumn.maxWidth = FilterViewConstants.iconColumnWidth
        iconColumn.isEditable = false

        let nameColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(nameColumnId))
        nameColumn.title = "Item"
        nameColumn.minWidth = FilterViewConstants.nameColumnMinWidth
        nameColumn.isEditable = false
        nameColumn.resizingMask = .autoresizingMask

        let kindColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(kindColumnId))
        kindColumn.title = "Kind"
        kindColumn.width = FilterViewConstants.kindColumnWidth
        kindColumn.minWidth = FilterViewConstants.kindColumnMinWidth
        kindColumn.maxWidth = FilterViewConstants.kindColumnWidth
        kindColumn.isEditable = false

        tableView.addTableColumn(iconColumn)
        tableView.addTableColumn(nameColumn)
        tableView.addTableColumn(kindColumn)

        // 设置列自动调整宽度
        tableView.sizeLastColumnToFit()
        tableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.headerView = nil

        tableContainer.documentView = tableView
    }

    // MARK: Public Methods

    func updateItems(_ items: [String]) {
        self.items = items
        tableView.reloadData()
    }

    func getSelectedRows() -> IndexSet {
        return tableView.selectedRowIndexes
    }

    // MARK: - Layout

    override func layout() {
        super.layout()
        adjustTableColumnsWidth()
        tableView.frame.size.width = tableContainer.contentSize.width
    }

    private func adjustTableColumnsWidth() {
        let nameColumnId = type == .process ? "ProcessNameColumn" : "MediaNameColumn"
        let iconColumnId = type == .process ? "ProcessIconColumn" : "MediaIconColumn"
        let kindColumnId = type == .process ? "ProcessKindColumn" : "MediaKindColumn"

        if let nameColumn = tableView.tableColumn(
            withIdentifier: NSUserInterfaceItemIdentifier(nameColumnId))
        {
            let totalWidth = tableContainer.contentSize.width
            let iconWidth =
                tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(iconColumnId))?
                .width ?? FilterViewConstants.iconColumnWidth
            let kindWidth =
                tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(kindColumnId))?
                .width ?? FilterViewConstants.kindColumnWidth

            // 减去其他列的宽度和间距
            nameColumn.width = totalWidth - iconWidth - kindWidth - 10
        }
    }

    // MARK: Actions

    @objc private func addItem() {
        delegate?.addItem(for: type)
    }

    @objc private func removeSelectedItems() {
        delegate?.removeItems(at: tableView.selectedRowIndexes, for: type)
    }

    @objc internal func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView == self.tableView
        else { return }
        removeButton.isEnabled = !tableView.selectedRowIndexes.isEmpty
    }

    @objc private func tableViewClicked(_ sender: NSTableView) {
        // 获取当前鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        guard let window = window else { return }
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        let viewPoint = convert(windowPoint, from: nil)
        let tablePoint = sender.convert(viewPoint, from: self)

        // 检查点击的是否是表格行
        let clickedRow = sender.row(at: tablePoint)

        // 如果点击的不是表格行，取消所有选择
        if clickedRow == -1 {
            sender.deselectAll(nil)
            removeButton.isEnabled = false
        }
    }

    // MARK: Context Menu

    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let removeItem = NSMenuItem(
            title: "Remove", action: #selector(contextMenuRemove(_:)), keyEquivalent: "")
        removeItem.target = self

        let openInFinderItem = NSMenuItem(
            title: "Open in Finder", action: #selector(contextMenuOpenInFinder(_:)),
            keyEquivalent: "")
        openInFinderItem.target = self

        menu.addItem(removeItem)
        menu.addItem(openInFinderItem)

        return menu
    }

    @objc private func contextMenuRemove(_ sender: NSMenuItem) {
        if !tableView.selectedRowIndexes.isEmpty {
            // 如果有选中的行，优先删除已选择的项目
            removeSelectedItems()
        } else {
            // 如果没有选中的行，删除右键点击的项目
            guard let clickInfo = sender.representedObject as? [String: Any],
                let row = clickInfo["row"] as? Int
            else {
                return
            }

            delegate?.removeItems(at: IndexSet(integer: row), for: type)
        }
    }

    @objc private func contextMenuOpenInFinder(_ sender: NSMenuItem) {
        guard let clickInfo = sender.representedObject as? [String: Any],
            let row = clickInfo["row"] as? Int,
            row < items.count
        else {
            return
        }

        let bundleID = items[row]
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        else {
            return
        }

        NSWorkspace.shared.selectFile(appURL.path, inFileViewerRootedAtPath: "")
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate

extension FilterTableView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int)
        -> NSView?
    {
        guard let tableColumn = tableColumn, row < items.count else { return nil }

        let bundleID = items[row]
        var appName: String?
        var appIcon: NSImage?

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
                make.size.equalTo(FilterViewConstants.iconSize)
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
                make.left.equalToSuperview().offset(FilterViewConstants.cellTextSideInset)
                make.right.equalToSuperview().offset(-FilterViewConstants.cellTextSideInset)
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
                make.left.equalToSuperview().offset(FilterViewConstants.cellTextSideInset)
                make.right.equalToSuperview().offset(-FilterViewConstants.cellTextSideInset)
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

        delegate?.addItems(bundleIDs, for: type)
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

extension FilterTableView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Get the location of the mouse click
        let mouseLocation = NSEvent.mouseLocation

        // Convert to window coordinates
        guard let window = window else { return }
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)

        // Convert to view coordinates
        let viewPoint = convert(windowPoint, from: nil)

        guard tableContainer.frame.contains(viewPoint) else {
            // Disable the menu items if click is outside the table container
            for item in menu.items {
                item.isEnabled = false
            }
            return
        }

        // Convert to table view coordinates
        let tablePoint = tableView.convert(viewPoint, from: self)

        // Get the row that was clicked
        let row = tableView.row(at: tablePoint)
        if row >= 0 {
            // Store the row in each menu item
            for item in menu.items {
                item.representedObject = ["row": row]
            }
        } else {
            // Disable the menu items if no valid row was clicked
            for item in menu.items {
                item.isEnabled = false
            }
        }
    }
}

// MARK: - CustomTableViewKeyHandler

extension FilterTableView: CustomTableViewKeyHandler {
    func handleDeleteKeyPress(in tableView: NSTableView) {
        removeSelectedItems()
    }
}

// MARK: - FilterTableViewDelegate

protocol FilterTableViewDelegate: AnyObject {
    func addItem(for type: FilterTableView.FilterType)
    func addItems(_ bundleIDs: [String], for type: FilterTableView.FilterType)
    func removeItems(at indexes: IndexSet, for type: FilterTableView.FilterType)
}

// MARK: - PreferencesFilterViewController

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

    // Filter Views
    private lazy var processFilterView = FilterTableView(type: .process)
    private lazy var mediaFilterView = FilterTableView(type: .media)

    override func loadView() {
        view = NSView()
        setupUI()
        bindData()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.documentView = contentView

        // Add filter views
        contentView.addSubview(processFilterView)
        contentView.addSubview(mediaFilterView)

        // Set delegates
        processFilterView.delegate = self
        mediaFilterView.delegate = self

        // Set constraints
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        processFilterView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(FilterViewConstants.filterViewTotalHeight)
        }

        mediaFilterView.snp.makeConstraints { make in
            make.top.equalTo(processFilterView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(FilterViewConstants.filterViewTotalHeight)
            make.bottom.equalToSuperview()
        }
    }

    private func bindData() {
        PreferencesDataModel.filteredProcesses
            .subscribe(onNext: { [weak self] processes in
                self?.processFilterView.updateItems(processes)
            })
            .disposed(by: disposeBag)

        PreferencesDataModel.filteredMediaProcesses
            .subscribe(onNext: { [weak self] media in
                self?.mediaFilterView.updateItems(media)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Layout Updates

    override func viewWillAppear() {
        super.viewWillAppear()
        processFilterView.layout()
        mediaFilterView.layout()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        processFilterView.layout()
        mediaFilterView.layout()
    }
}

// MARK: - FilterTableViewDelegate Implementation

extension PreferencesFilterViewController: FilterTableViewDelegate {
    func addItem(for type: FilterTableView.FilterType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message =
            type == .process
            ? "Choose applications to filter from process reporting"
            : "Choose applications to filter from media reporting"

        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard let self = self, response == .OK else { return }

            var bundleIDs: [String] = []
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                    bundleIDs.append(bundleID)
                }
            }

            self.addItems(bundleIDs, for: type)
        }
    }

    func addItems(_ bundleIDs: [String], for type: FilterTableView.FilterType) {
        if type == .process {
            var currentProcesses = PreferencesDataModel.filteredProcesses.value
            for bundleID in bundleIDs {
                if !currentProcesses.contains(bundleID) {
                    currentProcesses.append(bundleID)
                }
            }
            PreferencesDataModel.filteredProcesses.accept(currentProcesses)
        } else {
            var currentMedia = PreferencesDataModel.filteredMediaProcesses.value
            for bundleID in bundleIDs {
                if !currentMedia.contains(bundleID) {
                    currentMedia.append(bundleID)
                }
            }
            PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
        }
    }

    func removeItems(at indexes: IndexSet, for type: FilterTableView.FilterType) {
        if type == .process {
            var currentProcesses = PreferencesDataModel.filteredProcesses.value
            let sortedIndexes = indexes.sorted(by: >)
            for index in sortedIndexes {
                if index < currentProcesses.count {
                    currentProcesses.remove(at: index)
                }
            }
            PreferencesDataModel.filteredProcesses.accept(currentProcesses)
        } else {
            var currentMedia = PreferencesDataModel.filteredMediaProcesses.value
            let sortedIndexes = indexes.sorted(by: >)
            for index in sortedIndexes {
                if index < currentMedia.count {
                    currentMedia.remove(at: index)
                }
            }
            PreferencesDataModel.filteredMediaProcesses.accept(currentMedia)
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
