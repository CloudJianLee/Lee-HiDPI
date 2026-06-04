import Foundation

public struct DisplayOverridePayload: Equatable, Sendable {
    public var vendorID: UInt32
    public var productID: UInt32
    public var displayName: String
    public var hiDPIModes: [HiDPIMode]

    public init(vendorID: UInt32, productID: UInt32, displayName: String, hiDPIModes: [HiDPIMode]) {
        self.vendorID = vendorID
        self.productID = productID
        self.displayName = displayName
        self.hiDPIModes = hiDPIModes
    }

    public var directoryName: String {
        "DisplayVendorID-\(String(vendorID, radix: 16))"
    }

    public var fileName: String {
        "DisplayProductID-\(String(productID, radix: 16))"
    }

    public func propertyListDictionary() -> [String: Any] {
        [
            "DisplayProductName": displayName,
            "DisplayVendorID": vendorID,
            "DisplayProductID": productID,
            "scale-resolutions": hiDPIModes.map { mode in
                Self.encodeScaleResolution(backingPixels: mode.backingPixels)
            }
        ]
    }

    public func xmlPropertyListData() throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: propertyListDictionary(),
            format: .xml,
            options: 0
        )
    }

    public static func encodeScaleResolution(backingPixels: PixelSize) -> Data {
        var data = Data()
        data.appendBigEndianUInt32(UInt32(backingPixels.width))
        data.appendBigEndianUInt32(UInt32(backingPixels.height))
        return data
    }
}

public enum DisplayOverridePayloadFactory {
    public static func makePayload(
        for display: DisplayDescriptor,
        modes: [HiDPIMode]? = nil,
        policy: HiDPIGenerationPolicy = HiDPIGenerationPolicy()
    ) -> DisplayOverridePayload? {
        guard let vendorID = display.vendorID, let productID = display.productID else {
            return nil
        }

        let selectedModes = modes ?? HiDPIModeGenerator.generateModes(for: display, policy: policy)
        guard !selectedModes.isEmpty else {
            return nil
        }

        return DisplayOverridePayload(
            vendorID: vendorID,
            productID: productID,
            displayName: display.name,
            hiDPIModes: selectedModes
        )
    }
}

private extension Data {
    mutating func appendBigEndianUInt32(_ value: UInt32) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
