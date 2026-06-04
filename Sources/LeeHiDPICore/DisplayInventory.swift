import ApplicationServices
import Foundation

public enum DisplayInventoryError: Error, Equatable, LocalizedError {
    case cannotReadActiveDisplays(CGError)

    public var errorDescription: String? {
        switch self {
        case let .cannotReadActiveDisplays(error):
            "无法读取活动显示器：\(error)"
        }
    }
}

public protocol DisplayInventoryProviding: Sendable {
    func activeDisplays() throws -> [DisplayDescriptor]
}

public struct CoreGraphicsDisplayInventory: DisplayInventoryProviding {
    public init() {}

    public func activeDisplays() throws -> [DisplayDescriptor] {
        var count: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &count)
        guard result == .success else {
            throw DisplayInventoryError.cannotReadActiveDisplays(result)
        }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(count))
        result = CGGetActiveDisplayList(count, &displayIDs, &count)
        guard result == .success else {
            throw DisplayInventoryError.cannotReadActiveDisplays(result)
        }

        return displayIDs.map { displayID in
            let currentMode = CGDisplayCopyDisplayMode(displayID)
            let logicalWidth = currentMode.map { max($0.width, 1) } ?? max(CGDisplayPixelsWide(displayID), 1)
            let logicalHeight = currentMode.map { max($0.height, 1) } ?? max(CGDisplayPixelsHigh(displayID), 1)
            let backingWidth = currentMode.map { max($0.pixelWidth, logicalWidth) } ?? logicalWidth
            let backingHeight = currentMode.map { max($0.pixelHeight, logicalHeight) } ?? logicalHeight
            let vendorID = CGDisplayVendorNumber(displayID)
            let productID = CGDisplayModelNumber(displayID)
            let serialNumber = CGDisplaySerialNumber(displayID)

            return DisplayDescriptor(
                displayID: displayID,
                name: Self.name(for: displayID, vendorID: vendorID, productID: productID),
                nativePixels: PixelSize(width: backingWidth, height: backingHeight),
                logicalPoints: PixelSize(width: logicalWidth, height: logicalHeight),
                vendorID: vendorID == 0 ? nil : vendorID,
                productID: productID == 0 ? nil : productID,
                serialNumber: serialNumber == 0 ? nil : serialNumber,
                isBuiltin: CGDisplayIsBuiltin(displayID) != 0
            )
        }
    }

    private static func name(for displayID: CGDirectDisplayID, vendorID: UInt32, productID: UInt32) -> String {
        if CGDisplayIsBuiltin(displayID) != 0 {
            return "内建显示器"
        }

        if vendorID != 0 || productID != 0 {
            return "显示器 \(String(vendorID, radix: 16)):\(String(productID, radix: 16))"
        }

        return "显示器 \(displayID)"
    }
}
