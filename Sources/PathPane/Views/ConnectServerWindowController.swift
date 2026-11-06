// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Connect to Server Window Controller

@MainActor
class ConnectServerWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private var serverTypePopup: NSPopUpButton!
    private var hostField: NSTextField!
    private var portField: NSTextField!
    private var usernameField: NSTextField!
    private var passwordField: NSSecureTextField!
    private var pathField: NSTextField!
    
    private var connectButton: NSButton!
    private var cancelButton: NSButton!
    
    var onConnect: ((FileSystemConnectionConfig) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Connect to Server"
        window.center()
        
        super.init(window: window)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let padding: CGFloat = 20
        let spacing: CGFloat = 12
        var yOffset: CGFloat = padding
        
        // Server Type
        let serverTypeLabel = createLabel("Server Type:")
        serverTypePopup = NSPopUpButton(frame: .zero)
        serverTypePopup.addItems(withTitles: ["SMB/CIFS", "SFTP", "FTP"])
        serverTypePopup.target = self
        serverTypePopup.action = #selector(serverTypeChanged)
        
        let serverTypeStack = createStackView([serverTypeLabel, serverTypePopup])
        serverTypeStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(serverTypeStack)
        yOffset += 24 + spacing
        
        // Host
        let hostLabel = createLabel("Server Address:")
        hostField = createTextField()
        hostField.placeholderString = "example.com"
        
        let hostStack = createStackView([hostLabel, hostField])
        hostStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(hostStack)
        yOffset += 24 + spacing
        
        // Port (optional)
        let portLabel = createLabel("Port (optional):")
        portField = createTextField()
        portField.placeholderString = "Default"
        
        let portStack = createStackView([portLabel, portField])
        portStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(portStack)
        yOffset += 24 + spacing
        
        // Username
        let usernameLabel = createLabel("Username:")
        usernameField = createTextField()
        usernameField.placeholderString = "Optional"
        
        let usernameStack = createStackView([usernameLabel, usernameField])
        usernameStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(usernameStack)
        yOffset += 24 + spacing
        
        // Password
        let passwordLabel = createLabel("Password:")
        passwordField = NSSecureTextField(frame: .zero)
        passwordField.placeholderString = "Optional"
        
        let passwordStack = createStackView([passwordLabel, passwordField])
        passwordStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(passwordStack)
        yOffset += 24 + spacing
        
        // Path
        let pathLabel = createLabel("Path:")
        pathField = createTextField()
        pathField.placeholderString = "/"
        
        let pathStack = createStackView([pathLabel, pathField])
        pathStack.frame = NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24)
        contentView.addSubview(pathStack)
        yOffset += 24 + spacing + 10
        
        // Buttons
        connectButton = NSButton(frame: .zero)
        connectButton.title = "Connect"
        connectButton.bezelStyle = .rounded
        connectButton.target = self
        connectButton.action = #selector(connectClicked)
        connectButton.keyEquivalent = "\r"
        
        cancelButton = NSButton(frame: .zero)
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.keyEquivalent = "\u{1b}"
        
        let buttonStack = NSStackView(frame: NSRect(x: padding, y: yOffset, width: contentView.bounds.width - 2 * padding, height: 24))
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fill
        buttonStack.addArrangedSubview(NSView()) // Spacer
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(connectButton)
        contentView.addSubview(buttonStack)
        
        // Set initial port placeholder
        serverTypeChanged()
    }
    
    // MARK: - Helper Methods
    
    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(frame: .zero)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.alignment = .right
        label.preferredMaxLayoutWidth = 120
        return label
    }
    
    private func createTextField() -> NSTextField {
        let field = NSTextField(frame: .zero)
        field.bezelStyle = .roundedBezel
        return field
    }
    
    private func createStackView(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(frame: .zero)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 8
        views.forEach { stack.addArrangedSubview($0) }
        return stack
    }
    
    // MARK: - Actions
    
    @objc private func serverTypeChanged() {
        switch serverTypePopup.indexOfSelectedItem {
        case 0: // SMB
            portField.placeholderString = "445 (Default)"
        case 1: // SFTP
            portField.placeholderString = "22 (Default)"
        case 2: // FTP
            portField.placeholderString = "21 (Default)"
        default:
            break
        }
    }
    
    @objc private func connectClicked() {
        let host = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty else {
            NSSound.beep()
            return
        }
        
        let serverType: FileSystemConnectionConfig.ServerType
        switch serverTypePopup.indexOfSelectedItem {
        case 0:
            serverType = .smb
        case 1:
            serverType = .sftp
        case 2:
            serverType = .ftp
        default:
            serverType = .smb
        }
        
        let port = Int(portField.stringValue.trimmingCharacters(in: .whitespaces))
        let username = usernameField.stringValue.trimmingCharacters(in: .whitespaces)
        let password = passwordField.stringValue
        let path = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        
        let config = FileSystemConnectionConfig(
            serverType: serverType,
            host: host,
            port: port,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            path: path.isEmpty ? nil : path
        )
        
        onConnect?(config)
        close()
    }
    
    @objc private func cancelClicked() {
        close()
    }
}

// MARK: - NSWindowDelegate

extension ConnectServerWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up
    }
}