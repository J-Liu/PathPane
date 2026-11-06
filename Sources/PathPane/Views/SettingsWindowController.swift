import AppKit

// MARK: - Settings Window Controller

@MainActor
class SettingsWindowController: NSWindowController {

    // MARK: - Properties

    private var tabView: NSTabView!
    private var generalTab: NSView!
    private var aboutTab: NSView!

    // Layout constants
    private let labelWidth: CGFloat = 120
    private let controlWidth: CGFloat = 200
    private let rowSpacing: CGFloat = 16

    // MARK: - Singleton

    static let shared = SettingsWindowController()

    // MARK: - Initialization

    private init() {
        // Create window
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 550
        let height: CGFloat = 400
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        let frame = NSRect(x: x, y: y, width: width, height: height)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 450, height: 300)

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        tabView = NSTabView(frame: contentView.bounds.insetBy(dx: 10, dy: 10))
        tabView.autoresizingMask = [.width, .height]

        recreateTabs()

        contentView.addSubview(tabView)

        // Listen for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        recreateTabs()
    }

    private func recreateTabs() {
        // Remove existing tabs
        while let tab = tabView.tabViewItems.first {
            tabView.removeTabViewItem(tab)
        }

        generalTab = createGeneralTab()
        let generalItem = NSTabViewItem(identifier: "general")
        generalItem.label = L("settings.tab.general")
        generalItem.view = generalTab
        tabView.addTabViewItem(generalItem)

        aboutTab = createAboutTab()
        let aboutItem = NSTabViewItem(identifier: "about")
        aboutItem.label = L("settings.tab.about")
        aboutItem.view = aboutTab
        tabView.addTabViewItem(aboutItem)

        // Update window title
        window?.title = L("settings.title")
    }

    // MARK: - Public Methods

    func selectTab(withIdentifier identifier: String) {
        tabView.selectTabViewItem(withIdentifier: identifier)
    }

    // MARK: - Layout Helpers

    private func wrapInTopAlignedContainer(_ stack: NSStackView) -> NSView {
        let container = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        return container
    }

    private func makeRow(label: String, control: NSView) -> NSStackView {
        let labelField = NSTextField(labelWithString: label)
        labelField.alignment = .right
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true

        control.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [labelField, control])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        return row
    }

    private func makeVerticalStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = rowSpacing
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }

    // MARK: - Tab Creation

    private func createGeneralTab() -> NSView {
        let stack = makeVerticalStack()

        // Row: Theme
        let themePopup = NSPopUpButton()
        let themes: [(key: String, value: Int)] = [
            ("settings.theme.system", 0),
            ("settings.theme.light", 1),
            ("settings.theme.dark", 2)
        ]
        for theme in themes {
            themePopup.addItem(withTitle: L(theme.key))
            themePopup.lastItem?.representedObject = theme.value
        }
        let savedTheme = UserDefaults.standard.integer(forKey: "settings.theme")
        themePopup.selectItem(at: savedTheme)
        themePopup.target = self
        themePopup.action = #selector(themeChanged(_:))
        themePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.theme"), control: themePopup))

        // Row: Language
        let languagePopup = NSPopUpButton()
        for language in AppLanguage.allCases {
            languagePopup.addItem(withTitle: language.displayName)
            languagePopup.lastItem?.representedObject = language
        }
        let current = LocalizationManager.shared.currentLanguage
        if let index = AppLanguage.allCases.firstIndex(of: current) {
            languagePopup.selectItem(at: index)
        }
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged(_:))
        languagePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.language"), control: languagePopup))

        return wrapInTopAlignedContainer(stack)
    }

    // MARK: - Actions

    @objc private func themeChanged(_ sender: NSPopUpButton) {
        guard let value = sender.selectedItem?.representedObject as? Int else { return }
        UserDefaults.standard.set(value, forKey: "settings.theme")
        applyTheme(value)
    }

    private func applyTheme(_ value: Int) {
        switch value {
        case 1:
            NSApp.appearance = NSAppearance(named: .aqua)
        case 2:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        guard let selected = sender.selectedItem?.representedObject as? AppLanguage else { return }
        LocalizationManager.shared.setLanguage(selected)
    }

    private func createAboutTab() -> NSView {
        let container = NSView()

        let appIcon = NSImageView()
        if let image = NSImage(named: "NSApplicationIcon") {
            appIcon.image = image
        } else {
            appIcon.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
            appIcon.contentTintColor = .controlAccentColor
        }
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.widthAnchor.constraint(equalToConstant: 80).isActive = true
        appIcon.heightAnchor.constraint(equalToConstant: 80).isActive = true
        container.addSubview(appIcon)

        let nameLabel = NSTextField(labelWithString: "PathPane")
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let versionLabel = NSTextField(labelWithString: "\(L("settings.about.version")) \(version)")
        versionLabel.alignment = .center
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(versionLabel)

        let copyrightLabel = NSTextField(labelWithString: L("settings.about.copyright"))
        copyrightLabel.alignment = .center
        copyrightLabel.textColor = .secondaryLabelColor
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(copyrightLabel)

        let githubButton = NSButton(title: "github.com/J-Liu/PathPane", target: self, action: #selector(openGitHub))
        githubButton.bezelStyle = .rounded
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(githubButton)

        let licenseButton = NSButton(title: L("settings.about.license"), target: self, action: #selector(showLicense))
        licenseButton.bezelStyle = .rounded
        licenseButton.translatesAutoresizingMaskIntoConstraints = false

        let noticeButton = NSButton(title: L("settings.about.notice"), target: self, action: #selector(showNotice))
        noticeButton.bezelStyle = .rounded
        noticeButton.translatesAutoresizingMaskIntoConstraints = false

        let buttonRow = NSStackView(views: [licenseButton, noticeButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 16
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            appIcon.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            appIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            versionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            copyrightLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 8),
            copyrightLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            githubButton.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 24),
            githubButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            buttonRow.topAnchor.constraint(equalTo: githubButton.bottomAnchor, constant: 12),
            buttonRow.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            buttonRow.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    // MARK: - About Actions

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/J-Liu/PathPane") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showLicense() {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 350))
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

        let licenseText = """
        MIT License

        Copyright (c) 2026 Jia Liu

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        """

        textView.string = licenseText
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 500, height: 370))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let alert = NSAlert()
        alert.messageText = L("settings.about.license")
        alert.accessoryView = scrollView
        alert.addButton(withTitle: L("OK"))
        alert.beginSheetModal(for: window!)
    }

    @objc private func showNotice() {
        let notice = """
        PathPane - A native macOS file manager
        Copyright 2026 Jia Liu

        This product includes software developed by Jia Liu.

        The original PathPane project and its contributors must be credited
        in any redistribution or derivative work. This attribution notice must
        be retained in all copies or substantial portions of the software.
        """

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 200))
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 13, weight: .regular)
        textView.string = notice
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 500, height: 220))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let alert = NSAlert()
        alert.messageText = L("settings.about.notice")
        alert.accessoryView = scrollView
        alert.addButton(withTitle: L("OK"))
        alert.beginSheetModal(for: window!)
    }
}

// MARK: - NSWindowDelegate

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Window is not released, just hidden
    }
}