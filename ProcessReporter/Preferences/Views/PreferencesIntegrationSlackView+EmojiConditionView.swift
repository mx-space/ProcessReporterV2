import AppKit
import RxSwift
import SnapKit
import UniformTypeIdentifiers

extension PreferencesIntegrationSlackView {
	class EmojiConditionViewController: NSViewController {
		// MARK: - Properties

		private let disposeBag = DisposeBag()
		private var isEditing = false
		private var editingIndex: Int?
		private var conditions: [EmojiConditionList.EmojiCondition] = []

		// MARK: - UI Components

		private lazy var titleLabel: NSTextField = {
			let label = NSTextField(labelWithString: "Conditions")
			label.font = NSFont.boldSystemFont(ofSize: 16)
			return label
		}()

		private lazy var scrollView: NSScrollView = {
			let scrollView = NSScrollView()
			scrollView.hasVerticalScroller = true
			scrollView.borderType = .noBorder
			scrollView.autohidesScrollers = true
			return scrollView
		}()

		private lazy var contentView: NSView = {
			let view = NSView()
			return view
		}()

		private lazy var buttonStack: NSStackView = {
			let stackView = NSStackView()
			stackView.spacing = 8
			stackView.orientation = .horizontal
			stackView.distribution = .equalCentering
			return stackView
		}()

		private lazy var closeModalButton: NSButton = {
			let button = NSButton(title: "Close", target: self, action: #selector(cancel))
			button.bezelStyle = .rounded
			button.keyEquivalent = "\u{1b}"
			return button
		}()

		private lazy var saveButton: NSButton = {
			let button = NSButton(title: "Save", target: self, action: #selector(save))
			button.bezelStyle = .push
			button.keyEquivalent = "\r"
			return button
		}()

		private lazy var addButton: NSButton = {
			let button = NSButton(title: "Add Condition", target: self, action: #selector(addCondition))
			button.bezelStyle = .rounded
			return button
		}()

		// MARK: - View Lifecycle

		override func loadView() {
			view = NSView(frame: NSRect(origin: .zero, size: .init(width: 600, height: 500)))

			// Set title for window
			title = "Emoji Conditions"

			setupUI()
		}

		override func viewDidLoad() {
			super.viewDidLoad()
		}

		override func viewDidAppear() {
			// Load existing conditions
			loadExistingConditions()
		}

		private func loadExistingConditions() {
			conditions = PreferencesDataModel.shared.slackIntegration.value.customEmojiConditionList.getConditions()
			updateItems()
		}

		private func updateItems() {
			// 先清除已有的子视图
			for subview in contentView.subviews {
				subview.removeFromSuperview()
			}

			var previousItem: ConditionFormItemView?
			for (index, condition) in conditions.enumerated() {
				let itemView = ConditionFormItemView(initialValue: condition)
				contentView.addSubview(itemView)

				// Set delete handler
				itemView.onDelete = { [weak self] in
					self?.removeCondition(at: index)
				}

				itemView.snp.makeConstraints { make in
					make.horizontalEdges.equalToSuperview()

					if let previousItem = previousItem {
						make.top.equalTo(previousItem.snp.bottom).offset(16)
					} else {
						make.top.equalToSuperview()
					}
				}
				itemView.sizeToFit()
				previousItem = itemView
			}
		}

		private func removeCondition(at index: Int) {
			guard conditions.indices.contains(index) else { return }
			conditions.remove(at: index)
			updateItems()
		}

		private func setupUI() {
			view.addSubview(titleLabel)
			view.addSubview(scrollView)
			view.addSubview(buttonStack)

			setupButtonStack()

			// MARK: - ScrollView

			scrollView.documentView = contentView
			contentView.snp.makeConstraints { make in
				make.edges.equalToSuperview()
			}

			scrollView.snp.makeConstraints { make in
				make.top.equalTo(titleLabel.snp.bottom).offset(16)
				make.left.right.equalToSuperview().inset(20)
				make.bottom.equalTo(buttonStack.snp.top).offset(-16)
			}

			// MARK: - Title Label

			titleLabel.snp.makeConstraints { make in
				make.top.equalToSuperview().offset(16)
				make.left.equalToSuperview().offset(20)
			}
		}

		private func setupButtonStack() {
			buttonStack.addArrangedSubview(addButton)

			let rightStack = NSStackView()
			rightStack.orientation = .horizontal
			rightStack.distribution = .fill
			rightStack.addArrangedSubview(closeModalButton)
			rightStack.addArrangedSubview(saveButton)
			buttonStack.addArrangedSubview(rightStack)

			buttonStack.snp.makeConstraints { make in
				make.bottom.equalToSuperview().inset(16)
				make.horizontalEdges.equalToSuperview().inset(20)
			}
		}
	}
}

extension PreferencesIntegrationSlackView.EmojiConditionViewController {
	@objc func cancel() {
		dismiss(nil)
	}

	@objc func save() {
		// 获取所有 ConditionFormItemView 实例
		let itemViews = contentView.subviews.compactMap { $0 as? ConditionFormItemView }

		// 创建新的条件列表
		let newConditions = itemViews.map { $0.saveCondition() }

		// 更新到 Preferences 中
		var integration = PreferencesDataModel.shared.slackIntegration.value
		integration.customEmojiConditionList = EmojiConditionList(conditions: newConditions)
		PreferencesDataModel.shared.slackIntegration.accept(integration)

		// 关闭窗口
		dismiss(nil)
	}

	@objc func addCondition() {
		let itemView = ConditionFormItemView()

		NSAnimationContext.runAnimationGroup { context in
			context.duration = 0.3
			context.allowsImplicitAnimation = true
			let lastView = contentView.subviews.last
			contentView.addSubview(itemView)

			itemView.snp.makeConstraints { make in
				make.horizontalEdges.equalToSuperview()
				if let lastView = lastView as? ConditionFormItemView {
					make.top.equalTo(lastView.snp.bottom).offset(16)
				} else {
					make.top.equalToSuperview()
				}
			}

			contentView.layoutSubtreeIfNeeded()
			itemView.sizeToFit()
		}
	}
}

private class ConditionFormItemView: NSView {
	private lazy var formContainer: NSView = {
		let view = NSView()
		view.wantsLayer = true
		return view
	}()

	private lazy var conditionContainer: NSView = {
		let view = NSView()
		view.wantsLayer = true
		return view
	}()

	private lazy var ifLabel: NSTextField = {
		let label = NSTextField(labelWithString: "If")
		return label
	}()

	private lazy var fieldPopup: NSPopUpButton = {
		let popup = NSPopUpButton()
		popup.addItems(withTitles: EmojiConditionList.EmojiCondition.Variable.allCases.map { $0.toCopyableString() })
		popup.bezelStyle = .rounded
		popup.target = self
		popup.action = #selector(fieldChanged)
		return popup
	}()

	private lazy var conditionPopup: NSPopUpButton = {
		let popup = NSPopUpButton()
		popup.addItems(withTitles: EmojiConditionList.EmojiCondition.Condition.allCases.map { $0.rawValue })
		popup.bezelStyle = .rounded
		popup.target = self
		popup.action = #selector(conditionChanged)
		return popup
	}()

	private lazy var valueTextField: NSTextField = {
		let textField = NSTextField()
		textField.placeholderString = "Enter value..."
		return textField
	}()

	private lazy var appPickerButton: NSButton = {
		let button = NSButton()
		button.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "Select application")
		button.bezelStyle = .inline
		button.isBordered = false
		button.target = self
		button.action = #selector(openAppPicker)
		button.isHidden = true
		return button
	}()

	private lazy var thenSetEmojiLabel: NSTextField = {
		let label = NSTextField(labelWithString: "then set emoji to")
		return label
	}()

	private lazy var emojiTextField: NSTextField = {
		let textField = NSTextField()
		textField.placeholderString = "Enter emoji..."
		return textField
	}()

	private lazy var emojiPickerButton: NSButton = {
		let button = NSButton(title: "😀", target: nil, action: #selector(NSApp.orderFrontCharacterPalette))
		let emojiImage = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "open emoji panel")
		button.image = emojiImage
		button.bezelStyle = .inline
		button.isBordered = false
		return button
	}()

	private lazy var deleteButton: NSButton = {
		let button = NSButton()
		button.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete condition")
		button.bezelStyle = .inline
		button.isBordered = false
		button.target = self
		button.action = #selector(deleteCondition)
		return button
	}()

	var onDelete: (() -> Void)?

	@objc private func deleteCondition() {
		onDelete?()
	}

	@objc private func fieldChanged() {
		updateAppPickerVisibility()
	}

	@objc private func conditionChanged() {
		updateAppPickerVisibility()
	}

	private func updateAppPickerVisibility() {
		let allowedApplicationInentifier: Set<EmojiConditionList.EmojiCondition.Variable> = [.processApplicationIdentifier, .mediaProcessApplicationIdentifier]
		let isAppId = allowedApplicationInentifier.contains(EmojiConditionList.EmojiCondition.Variable.allCases[fieldPopup.indexOfSelectedItem])
		let isEquals = EmojiConditionList.EmojiCondition.Condition.allCases[conditionPopup.indexOfSelectedItem] == .equals

		appPickerButton.isHidden = !(isAppId && isEquals)
	}

	@objc private func openAppPicker() {
		AppPickerView.showAppPicker(for: appPickerButton) { [weak self] appId, _ in
			guard let self = self else { return }
			self.valueTextField.stringValue = appId ?? ""
		}
	}

	init(initialValue: EmojiConditionList.EmojiCondition? = nil) {
		super.init(frame: .zero)
		setupUI()

		if let initialValue = initialValue {
			setValues(from: initialValue)
		}

		updateAppPickerVisibility()
	}

	private func setValues(from condition: EmojiConditionList.EmojiCondition) {
		if let parsedCondition = EmojiConditionList.EmojiCondition.parseWhenString(for: condition.when) {
			// 设置表达式下拉菜单
			for (index, variable) in EmojiConditionList.EmojiCondition.Variable.allCases.enumerated() {
				if variable == parsedCondition.variable {
					fieldPopup.selectItem(at: index)
					break
				}
			}

			// 设置条件下拉菜单
			for (index, condition) in EmojiConditionList.EmojiCondition.Condition.allCases.enumerated() {
				if condition == parsedCondition.condition {
					conditionPopup.selectItem(at: index)
					break
				}
			}

			// 设置值
			valueTextField.stringValue = parsedCondition.value
		}

		// 设置 emoji
		emojiTextField.stringValue = condition.emoji

		// Update app picker visibility based on current selection
		updateAppPickerVisibility()
	}

	func saveCondition() -> EmojiConditionList.EmojiCondition {
		// 获取选中的变量
		let variableIndex = fieldPopup.indexOfSelectedItem
		let variable = EmojiConditionList.EmojiCondition.Variable.allCases[variableIndex]

		// 获取选中的条件
		let conditionIndex = conditionPopup.indexOfSelectedItem
		let condition = EmojiConditionList.EmojiCondition.Condition.allCases[conditionIndex]

		// 构建 when 字符串: "{variable} condition "value""
		let whenString = "{\(variable.rawValue)} \(condition.rawValue) \"\(valueTextField.stringValue)\""

		// 返回新的条件对象
		return EmojiConditionList.EmojiCondition(when: whenString, emoji: emojiTextField.stringValue)
	}

	func sizeToFit() {
		snp.makeConstraints { make in
			make.bottom.equalTo(conditionContainer).offset(8)
		}
	}

	private func setupUI() {
		addSubview(formContainer)
		formContainer.addSubview(conditionContainer)
		formContainer.addSubview(emojiPickerButton)
		formContainer.addSubview(deleteButton)

		formContainer.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

		conditionContainer.addSubview(ifLabel)
		conditionContainer.addSubview(fieldPopup)
		conditionContainer.addSubview(conditionPopup)
		conditionContainer.addSubview(valueTextField)
		conditionContainer.addSubview(appPickerButton)
		conditionContainer.addSubview(thenSetEmojiLabel)
		conditionContainer.addSubview(emojiTextField)

		conditionContainer.snp.makeConstraints { make in
			make.top.equalTo(snp.top).offset(16)
			make.left.right.equalToSuperview().inset(20)
		}

		ifLabel.snp.makeConstraints { make in
			make.left.equalToSuperview()
			make.bottom.equalTo(fieldPopup).offset(-4)
		}

		fieldPopup.snp.makeConstraints { make in
			make.top.equalToSuperview()
			make.left.equalTo(ifLabel.snp.right).offset(8)
			make.width.equalTo(140)
			make.height.equalTo(24)
		}

		conditionPopup.snp.makeConstraints { make in
			make.top.equalToSuperview()
			make.left.equalTo(fieldPopup.snp.right).offset(8)
			make.width.equalTo(140)
			make.height.equalTo(24)
		}

		valueTextField.snp.makeConstraints { make in
			make.top.equalToSuperview()
			make.left.equalTo(conditionPopup.snp.right).offset(8)
			make.right.equalToSuperview()
			make.height.equalTo(24)
		}

		appPickerButton.snp.makeConstraints { make in
			make.centerY.equalTo(valueTextField)
			make.right.equalTo(valueTextField.snp.right).offset(-4)
			make.size.equalTo(24)
		}

		thenSetEmojiLabel.snp.makeConstraints { make in
			make.left.equalToSuperview()
			make.bottom.equalTo(emojiTextField.snp.bottom).offset(-4)
		}

		emojiTextField.snp.makeConstraints { make in
			make.top.equalTo(fieldPopup.snp.bottom).offset(16)
			make.left.equalTo(thenSetEmojiLabel.snp.right).offset(8)
			make.width.equalTo(200)
			make.height.equalTo(24)
			make.bottom.equalToSuperview()
		}

		emojiPickerButton.snp.makeConstraints { make in
			make.centerY.equalTo(emojiTextField)
			make.left.equalTo(emojiTextField.snp.right).offset(4)
			make.size.equalTo(24)
		}

		deleteButton.snp.makeConstraints { make in
			make.bottom.equalTo(emojiPickerButton)
			make.right.equalToSuperview().offset(-18)
			make.size.equalTo(24)
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
