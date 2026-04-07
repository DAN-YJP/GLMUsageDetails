import Foundation
import XCTest

final class AppIconAssetTests: XCTestCase {
    func testAppIconAssetContainsMacOSIconFiles() throws {
        let assetDirectory = repositoryRoot()
            .appendingPathComponent("UsageMonitorApp/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
        let contentsURL = assetDirectory.appendingPathComponent("Contents.json")
        let data = try Data(contentsOf: contentsURL)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let images = try XCTUnwrap(object["images"] as? [[String: Any]])

        XCTAssertFalse(images.isEmpty, "App icon asset must declare macOS icon files.")

        let fileNames = images.compactMap { $0["filename"] as? String }
        XCTAssertTrue(fileNames.contains("icon_512x512@2x.png"), "App icon asset must include a 1024px source image.")

        for fileName in fileNames {
            let fileURL = assetDirectory.appendingPathComponent(fileName)
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Missing app icon file: \(fileName)")
        }
    }

    func testBundleDeclaresStandaloneICNSIcon() throws {
        let repositoryRoot = repositoryRoot()
        let iconURL = repositoryRoot.appendingPathComponent("UsageMonitorApp/AppIcon.icns")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iconURL.path), "App bundle should include a standalone ICNS file for Finder and DMG installs.")

        let plistURL = repositoryRoot.appendingPathComponent("UsageMonitorApp/Info.plist")
        let plistData = try Data(contentsOf: plistURL)
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any])
        XCTAssertEqual(plist["CFBundleIconFile"] as? String, "AppIcon", "Info.plist should explicitly reference the bundled app icon.")
    }

    func testIconGenerationScriptUsesRootIconPNGAsSourceArtwork() throws {
        let repositoryRoot = repositoryRoot()
        let sourceIconURL = repositoryRoot.appendingPathComponent("icon.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceIconURL.path), "Repository should include icon.png as the source artwork.")

        let scriptURL = repositoryRoot.appendingPathComponent("Scripts/generate_app_icon.swift")
        let scriptContents = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(scriptContents.contains("icon.png"), "Icon generation should use the repository root icon.png as its source.")
    }

    private func repositoryRoot(filePath: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
