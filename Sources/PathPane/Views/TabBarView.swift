// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Tab Bar View

@MainActor
class TabBarView: NSView {

    // MARK: - Properties

    weak var delegate: TabBarViewDelegate?
    private var tabViews: [TabItemView] = []

    // MARK: - UI Elements

    private lazy var stackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 2
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fill
        return stack
    }()

    private lazy var newTabButton: NSButton = {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Tab")
        button.bezelStyle = .inline
        button.isBordered = false
        button.target = self
        button.action = #selector(createNewTab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.toolTip = "New Tab (⌘T)"

        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true

        return button
    }()

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        addSubview(stackView)
        addSubview(newTabButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            newTabButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8),
            newTabButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            newTabButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }

    // MARK: - Tab Management

    func updateTabs(_ tabs: [Tab], activeIndex: Int) {
        // Remove existing views
        tabViews.forEach { $0.removeFromSuperview() }
        tabViews.removeAll()

        // Create new tab views
        for (index, tab) in tabs.enumerated() {
            let tabView = TabItemView(title: tab.directoryState.currentURL.lastPathComponent, index: index)
            tabView.isActive = index == activeIndex
            tabView.delegate = self
            tabViews.append(tabView)
            stackView.addArrangedSubview(tabView)
        }
    }

    // MARK: - Actions

    @objc private func createNewTab() {
        delegate?.tabBarViewDidRequestNewTab()
    }
}

// MARK: - TabItemViewDelegate

extension TabBarView: TabItemViewDelegate {
    func tabItemView(_ view: TabItemView, didSelectAt index: Int) {
        delegate?.tabBarView(self, didSelectTabAt: index)
    }

    func tabItemView(_ view: TabItemView, didRequestCloseAt index: Int) {
        delegate?.tabBarView(self, didRequestCloseTabAt: index)
    }
}

// MARK: - Tab Item View

class TabItemView: NSView {

    // MARK: - Properties

    weak var delegate: TabItemViewDelegate?
    let index: Int
    var isActive: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    private var title: String

    // MARK: - UI Elements

    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var closeButton: NSButton = {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        button.image?.size = NSSize(width: 10, height: 10)
        button.bezelStyle = .inline
        button.isBordered = false
        button.target = self
        button.action = #selector(closeTab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.toolTip = "Close Tab (⌘W)"

        button.widthAnchor.constraint(equalToConstant: 16).isActive = true
        button.heightAnchor.constraint(equalToConstant: 16).isActive = true

        return button
    }()

    private lazy var containerStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(title: String, index: Int) {
        self.title = title
        self.index = index
        super.init(frame: .zero)

        setupView()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6

        titleLabel.stringValue = title
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(closeButton)

        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])

        // Click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
    }

    private func updateAppearance() {
        if isActive {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
            closeButton.isHidden = false
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            titleLabel.font = .systemFont(ofSize: 11)
            closeButton.isHidden = true
        }
    }

    func updateTitle(_ newTitle: String) {
        title = newTitle
        titleLabel.stringValue = newTitle
    }

    // MARK: - Actions

    @objc private func handleClick() {
        delegate?.tabItemView(self, didSelectAt: index)
    }

    @objc private func closeTab() {
        delegate?.tabItemView(self, didRequestCloseAt: index)
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        if !isActive {
            layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
            closeButton.isHidden = false
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !isActive {
            layer?.backgroundColor = NSColor.clear.cgColor
            closeButton.isHidden = true
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
}

// MARK: - TabItemViewDelegate

@MainActor
protocol TabItemViewDelegate: AnyObject {
    func tabItemView(_ view: TabItemView, didSelectAt index: Int)
    func tabItemView(_ view: TabItemView, didRequestCloseAt index: Int)
}

// MARK: - Tab Bar View Delegate

@MainActor
protocol TabBarViewDelegate: AnyObject {
    func tabBarViewDidRequestNewTab()
    func tabBarView(_ view: TabBarView, didSelectTabAt index: Int)
    func tabBarView(_ view: TabBarView, didRequestCloseTabAt index: Int)
}