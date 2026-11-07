// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import QuickLookThumbnailing

// MARK: - Info Window Controller

class InfoWindowController: NSWindowController {

    // MARK: - Properties

    private var fileItem: FileItem

    // MARK: - UI Elements

    private lazy var iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()

    private lazy var nameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private lazy var kindLabel: NSTextField = {
        return createDetailLabel()
    }()

    private lazy var sizeLabel: NSTextField = {
        return createDetailLabel()
    }()

    private lazy var createdLabel: NSTextField = {
        return createDetailLabel()
    }()

    private lazy var modifiedLabel: NSTextField = {
        return createDetailLabel()
    }()

    private lazy var locationLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingMiddle
        label.isSelectable = true
        return label
    }()

    // MARK: - Initialization

    init(fileItem: FileItem) {
        self.fileItem = fileItem

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Info"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupUI()
        loadFileInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Icon and name
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .centerY
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        iconView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        headerStack.addArrangedSubview(iconView)
        headerStack.addArrangedSubview(nameLabel)

        stackView.addArrangedSubview(headerStack)

        // Details
        let detailsStack = NSStackView()
        detailsStack.orientation = .vertical
        detailsStack.spacing = 8
        detailsStack.alignment = .leading
        detailsStack.translatesAutoresizingMaskIntoConstraints = false

        detailsStack.addArrangedSubview(createDetailRow(title: L("info.kind"), value: kindLabel))
        detailsStack.addArrangedSubview(createDetailRow(title: L("info.size"), value: sizeLabel))
        detailsStack.addArrangedSubview(createDetailRow(title: L("info.created"), value: createdLabel))
        detailsStack.addArrangedSubview(createDetailRow(title: L("info.modified"), value: modifiedLabel))

        stackView.addArrangedSubview(detailsStack)

        // Location
        let locationStack = NSStackView()
        locationStack.orientation = .vertical
        locationStack.spacing = 4
        locationStack.alignment = .leading
        locationStack.translatesAutoresizingMaskIntoConstraints = false

        let locationTitle = NSTextField(labelWithString: L("info.location"))
        locationTitle.font = .systemFont(ofSize: 11, weight: .medium)
        locationTitle.textColor = .labelColor
        locationStack.addArrangedSubview(locationTitle)
        locationStack.addArrangedSubview(locationLabel)

        stackView.addArrangedSubview(locationStack)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func createDetailLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createDetailRow(title: String, value: NSTextField) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(value)

        return stack
    }

    // MARK: - Load File Info

    private func loadFileInfo() {
        // Load icon
        let request = QLThumbnailGenerator.Request(
            fileAt: fileItem.url,
            size: NSSize(width: 64, height: 64),
            scale: 2.0,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { [weak self] thumbnail, _, error in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    self?.iconView.image = thumbnail.nsImage
                } else {
                    self?.iconView.image = NSImage(systemSymbolName: self?.fileItem.isDirectory == true ? "folder" : "doc", accessibilityDescription: nil)
                }
            }
        }

        // Set name
        nameLabel.stringValue = fileItem.name

        // Get file attributes
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileItem.url.path)

            // Kind
            if let type = attributes[.type] as? FileAttributeType {
                if type == .typeDirectory {
                    kindLabel.stringValue = L("info.kind.folder")
                } else {
                    // Get UTI and localized description
                    if let uti = try? URL(fileURLWithPath: fileItem.url.path).resourceValues(forKeys: [.contentTypeKey]).contentType {
                        kindLabel.stringValue = uti.localizedDescription ?? L("info.kind.file")
                    } else {
                        kindLabel.stringValue = L("info.kind.file")
                    }
                }
            }

            // Size
            if let size = attributes[.size] as? Int64 {
                if fileItem.isDirectory {
                    sizeLabel.stringValue = "—"
                } else {
                    sizeLabel.stringValue = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                }
            }

            // Dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            if let creationDate = attributes[.creationDate] as? Date {
                createdLabel.stringValue = dateFormatter.string(from: creationDate)
            }

            if let modificationDate = attributes[.modificationDate] as? Date {
                modifiedLabel.stringValue = dateFormatter.string(from: modificationDate)
            }

        } catch {
            kindLabel.stringValue = L("info.kind.unknown")
        }

        // Location
        locationLabel.stringValue = fileItem.url.deletingLastPathComponent().path
    }
}