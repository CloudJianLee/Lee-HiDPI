import Foundation

public struct DisplayOverrideExport: Equatable, Sendable {
    public var fileURL: URL
    public var backupURL: URL?
    public var modeCount: Int

    public init(fileURL: URL, backupURL: URL?, modeCount: Int) {
        self.fileURL = fileURL
        self.backupURL = backupURL
        self.modeCount = modeCount
    }
}

public enum DisplayOverrideStoreError: Error, Equatable, LocalizedError {
    case refusedBuiltinDisplay
    case missingVendorOrProductID
    case emptyModes

    public var errorDescription: String? {
        switch self {
        case .refusedBuiltinDisplay:
            "已拒绝为内建显示器创建 override。"
        case .missingVendorOrProductID:
            "显示器缺少 vendor 或 product 标识。"
        case .emptyModes:
            "没有为这台显示器生成 HiDPI 模式。"
        }
    }
}

public struct DisplayOverrideStore {
    public var rootDirectory: URL
    public var fileManager: FileManager

    public init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    public static var defaultUserExportStore: DisplayOverrideStore {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let root = documents ?? URL(fileURLWithPath: NSHomeDirectory())
        return DisplayOverrideStore(rootDirectory: root.appendingPathComponent("LeeHiDPIOverrides", isDirectory: true))
    }

    public static var systemOverrideStore: DisplayOverrideStore {
        DisplayOverrideStore(
            rootDirectory: URL(fileURLWithPath: "/Library/Displays/Contents/Resources/Overrides", isDirectory: true)
        )
    }

    @discardableResult
    public func export(payload: DisplayOverridePayload, backupExisting: Bool = true) throws -> DisplayOverrideExport {
        let directory = rootDirectory.appendingPathComponent(payload.directoryName, isDirectory: true)
        let fileURL = directory.appendingPathComponent(payload.fileName)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var backupURL: URL?
        if backupExisting, fileManager.fileExists(atPath: fileURL.path) {
            let backup = fileURL.appendingPathExtension("bak-\(Self.timestamp())")
            try fileManager.copyItem(at: fileURL, to: backup)
            backupURL = backup
        }

        try payload.xmlPropertyListData().write(to: fileURL, options: .atomic)
        return DisplayOverrideExport(fileURL: fileURL, backupURL: backupURL, modeCount: payload.hiDPIModes.count)
    }

    @discardableResult
    public func export(
        display: DisplayDescriptor,
        modes: [HiDPIMode]? = nil,
        policy: HiDPIGenerationPolicy = HiDPIGenerationPolicy()
    ) throws -> DisplayOverrideExport {
        guard !display.isBuiltin else {
            throw DisplayOverrideStoreError.refusedBuiltinDisplay
        }

        guard let payload = DisplayOverridePayloadFactory.makePayload(for: display, modes: modes, policy: policy) else {
            if display.vendorID == nil || display.productID == nil {
                throw DisplayOverrideStoreError.missingVendorOrProductID
            }
            throw DisplayOverrideStoreError.emptyModes
        }

        return try export(payload: payload)
    }

    public func restoreBackup(_ backupURL: URL, to fileURL: URL) throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        try fileManager.copyItem(at: backupURL, to: fileURL)
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: Date()).replacingOccurrences(of: ":", with: "")
    }
}
