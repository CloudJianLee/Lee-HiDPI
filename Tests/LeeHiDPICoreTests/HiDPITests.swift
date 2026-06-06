import Foundation
import Testing
@testable import LeeHiDPICore

@Test func modeUsesTwoTimesBackingPixels() {
    let mode = HiDPIMode(logicalPoints: PixelSize(width: 1920, height: 1080))

    #expect(mode.logicalPoints == PixelSize(width: 1920, height: 1080))
    #expect(mode.backingPixels == PixelSize(width: 3840, height: 2160))
    #expect(mode.description == "1920x1080 HiDPI（3840x2160 渲染）")
}

@Test func generatorKeepsNativeAspectRatio() {
    let display = DisplayDescriptor(
        displayID: 1,
        name: "4K External",
        nativePixels: PixelSize(width: 3840, height: 2160)
    )

    let modes = HiDPIModeGenerator.generateModes(for: display)

    #expect(modes.contains(HiDPIMode(logicalPoints: PixelSize(width: 1920, height: 1080))))
    #expect(modes.allSatisfy { abs($0.logicalPoints.aspectRatio - (16.0 / 9.0)) <= 0.01 })
}

@Test func generatorHonorsBackingPixelBudget() {
    let display = DisplayDescriptor(
        displayID: 1,
        name: "4K External",
        nativePixels: PixelSize(width: 3840, height: 2160)
    )
    let policy = HiDPIGenerationPolicy(maximumBackingPixelMultiplier: 1.0)

    let modes = HiDPIModeGenerator.generateModes(for: display, policy: policy)

    #expect(modes.allSatisfy { $0.backingPixels.width <= 3840 })
    #expect(!modes.contains(HiDPIMode(logicalPoints: PixelSize(width: 2304, height: 1296))))
}

@Test func recommendedModeDefaultsToNativeHalfWidth() {
    let display = DisplayDescriptor(
        displayID: 1,
        name: "5K Studio",
        nativePixels: PixelSize(width: 5120, height: 2880)
    )

    let mode = HiDPIModeGenerator.recommendedMode(for: display)

    #expect(mode?.logicalPoints == PixelSize(width: 2560, height: 1440))
}

@Test func recommendedStateRequiresExactLogicalAndBackingMode() {
    let optimal = DisplayDescriptor(
        displayID: 2,
        name: "QHD External",
        nativePixels: PixelSize(width: 3840, height: 2160),
        logicalPoints: PixelSize(width: 1920, height: 1080)
    )
    let otherHiDPI = DisplayDescriptor(
        displayID: 2,
        name: "QHD External",
        nativePixels: PixelSize(width: 4096, height: 2304),
        logicalPoints: PixelSize(width: 2048, height: 1152)
    )
    let standard = DisplayDescriptor(
        displayID: 2,
        name: "QHD External",
        nativePixels: PixelSize(width: 2560, height: 1440),
        logicalPoints: PixelSize(width: 2560, height: 1440)
    )

    #expect(DisplayRecommendationEngine.isRecommendedModeActive(for: optimal))
    #expect(!DisplayRecommendationEngine.isRecommendedModeActive(for: otherHiDPI))
    #expect(!DisplayRecommendationEngine.isRecommendedModeActive(for: standard))
}

@Test func displayOverrideEncodesBackingResolutionAsBigEndianData() throws {
    let mode = HiDPIMode(logicalPoints: PixelSize(width: 1920, height: 1080))
    let payload = DisplayOverridePayload(
        vendorID: 0x1234,
        productID: 0xabcd,
        displayName: "Prototype 4K",
        hiDPIModes: [mode]
    )

    #expect(payload.directoryName == "DisplayVendorID-1234")
    #expect(payload.fileName == "DisplayProductID-abcd")
    #expect(DisplayOverridePayload.encodeScaleResolution(backingPixels: mode.backingPixels) == Data([
        0x00, 0x00, 0x0f, 0x00,
        0x00, 0x00, 0x08, 0x70
    ]))

    let plist = try payload.xmlPropertyListData()
    #expect(String(data: plist, encoding: .utf8)?.contains("scale-resolutions") == true)
}

@Test func payloadFactoryRequiresVendorAndProductIDs() {
    let display = DisplayDescriptor(
        displayID: 2,
        name: "Unknown External",
        nativePixels: PixelSize(width: 3840, height: 2160)
    )

    #expect(DisplayOverridePayloadFactory.makePayload(for: display) == nil)
}

@Test func overrideStoreExportsNestedDisplayOverrideFile() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let display = DisplayDescriptor(
        displayID: 2,
        name: "Prototype 4K",
        nativePixels: PixelSize(width: 3840, height: 2160),
        vendorID: 0x1234,
        productID: 0xabcd
    )
    let store = DisplayOverrideStore(rootDirectory: root)

    let export = try store.export(display: display)

    #expect(export.fileURL.lastPathComponent == "DisplayProductID-abcd")
    #expect(export.fileURL.deletingLastPathComponent().lastPathComponent == "DisplayVendorID-1234")
    #expect(export.modeCount > 0)
    #expect(FileManager.default.fileExists(atPath: export.fileURL.path))
}

@Test func overrideStoreBacksUpExistingFile() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let payload = DisplayOverridePayload(
        vendorID: 0x1234,
        productID: 0xabcd,
        displayName: "Prototype 4K",
        hiDPIModes: [HiDPIMode(logicalPoints: PixelSize(width: 1920, height: 1080))]
    )
    let store = DisplayOverrideStore(rootDirectory: root)

    _ = try store.export(payload: payload, backupExisting: false)
    let secondExport = try store.export(payload: payload, backupExisting: true)

    #expect(secondExport.backupURL != nil)
    #expect(secondExport.backupURL.map { FileManager.default.fileExists(atPath: $0.path) } == true)
}

@Test func overrideStoreRefusesBuiltinDisplays() throws {
    let display = DisplayDescriptor(
        displayID: 1,
        name: "Built-in Display",
        nativePixels: PixelSize(width: 3024, height: 1964),
        vendorID: 0x610,
        productID: 0xa045,
        isBuiltin: true
    )
    let store = DisplayOverrideStore(rootDirectory: FileManager.default.temporaryDirectory)

    #expect(throws: DisplayOverrideStoreError.refusedBuiltinDisplay) {
        try store.export(display: display)
    }
}
