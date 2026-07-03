import AppKit
import UniformTypeIdentifiers

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let controller = SettingsViewController()
        let window = NSWindow(contentViewController: controller)
        window.title = "HitHint"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
    }
}

final class SettingsViewController: NSViewController {
    private var dropView: AppDropView { view as! AppDropView }

    override func loadView() {
        view = AppDropView(frame: NSRect(x: 0, y: 0, width: 480, height: 440))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: ExcludedApps.changedNotification, object: nil, queue: .main) { [weak self] _ in
            self?.dropView.reload()
        }
        dropView.reload()
    }
}

final class AppDropView: NSView {
    private let titleLabel = NSTextField(labelWithString: "Excluded apps")
    private let bodyLabel = NSTextField(wrappingLabelWithString: "Drag apps here from Finder or the Applications folder. HitHint stays inactive while an excluded app is frontmost.")
    private let emptyLabel = NSTextField(labelWithString: "No excluded apps yet")
    private let scrollView = NSScrollView()
    private let listView = FlippedView()
    private var highlighted = false {
        didSet { needsDisplay = true }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 24, y: frame.height - 52, width: 432, height: 28)
        titleLabel.autoresizingMask = [.minYMargin]

        bodyLabel.frame = NSRect(x: 24, y: frame.height - 104, width: 432, height: 44)
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.autoresizingMask = [.minYMargin]

        emptyLabel.textColor = .tertiaryLabelColor
        emptyLabel.alignment = .center

        scrollView.frame = NSRect(x: 24, y: 24, width: 432, height: frame.height - 140)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = listView

        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        listView.subviews.forEach { $0.removeFromSuperview() }
        let ids = ExcludedApps.bundleIdentifiers
        let rowHeight: CGFloat = 40
        let width = scrollView.contentSize.width
        listView.frame = NSRect(x: 0, y: 0, width: width, height: max(scrollView.contentSize.height, CGFloat(ids.count) * rowHeight))

        if ids.isEmpty {
            emptyLabel.frame = NSRect(x: 0, y: scrollView.contentSize.height / 2 - 12, width: width, height: 24)
            listView.addSubview(emptyLabel)
            return
        }

        for (index, id) in ids.enumerated() {
            let row = FlippedView(frame: NSRect(x: 0, y: CGFloat(index) * rowHeight, width: width, height: rowHeight))

            let iconView = NSImageView(frame: NSRect(x: 4, y: 6, width: 28, height: 28))
            iconView.image = ExcludedApps.icon(for: id)

            let nameLabel = NSTextField(labelWithString: ExcludedApps.displayName(for: id))
            nameLabel.frame = NSRect(x: 44, y: 10, width: width - 96, height: 20)
            nameLabel.lineBreakMode = .byTruncatingTail

            let removeButton = NSButton(title: "", target: self, action: #selector(removeApp(_:)))
            removeButton.bezelStyle = .inline
            removeButton.isBordered = false
            removeButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Remove \(id)")
            removeButton.contentTintColor = .secondaryLabelColor
            removeButton.frame = NSRect(x: width - 40, y: 8, width: 24, height: 24)
            removeButton.identifier = NSUserInterfaceItemIdentifier(id)

            let separator = NSBox(frame: NSRect(x: 0, y: rowHeight - 1, width: width, height: 1))
            separator.boxType = .separator

            row.addSubview(iconView)
            row.addSubview(nameLabel)
            row.addSubview(removeButton)
            if index < ids.count - 1 {
                row.addSubview(separator)
            }
            listView.addSubview(row)
        }
    }

    @objc private func removeApp(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        ExcludedApps.remove(id)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard highlighted else { return }
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), xRadius: 12, yRadius: 12)
        NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
        path.fill()
        NSColor.controlAccentColor.setStroke()
        path.lineWidth = 2.5
        path.stroke()
    }

    private func appURLs(from sender: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
        return urls.filter { $0.pathExtension == "app" }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !appURLs(from: sender).isEmpty else { return [] }
        highlighted = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        highlighted = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        highlighted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        highlighted = false
        var added = false
        for url in appURLs(from: sender) {
            if let id = Bundle(url: url)?.bundleIdentifier {
                ExcludedApps.add(id)
                added = true
            }
        }
        return added
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
