import XCTest
@testable import BarkMacCore

final class PolicyTests: XCTestCase {
    func testRegistrationIsNeverAllowed() {
        let samples = [
            "",
            "   ",
            "https://api.day.app",
            "https://API.DAY.APP/register",
            "https://user:token@api.day.app",
            "https://bark.example",
            "https://api.day.app.evil.example"
        ]
        for sample in samples {
            let decision = RegistrationPolicy.decision(forAddress: sample)
            XCTAssertFalse(decision.allowed, sample)
            XCTAssertEqual(decision.deviceType, "macos", sample)
            XCTAssertFalse(decision.statusLine.contains("已连接"), decision.statusLine)
            XCTAssertFalse(decision.statusLine.contains("已验证"), decision.statusLine)
        }
        XCTAssertFalse(RegistrationPolicy.networkRegistrationEnabled)
        XCTAssertEqual(RegistrationPolicy.decision(forAddress: "").block, .emptyAddress)
        XCTAssertEqual(RegistrationPolicy.decision(forAddress: "https://api.day.app").block, .officialServer)
        XCTAssertEqual(RegistrationPolicy.decision(forAddress: "https://bark.example").block, .macosDeviceTypeNotAccepted)
        XCTAssertEqual(
            RegistrationPolicy.decision(forAddress: "https://api.day.app.evil.example").block,
            .macosDeviceTypeNotAccepted
        )
    }

    func testAddressSaveDoesNotImplyConnection() {
        XCTAssertEqual(AddressDraft.evaluate("  "), .cleared)
        XCTAssertEqual(AddressDraft.evaluate("https://bark.example/"), .saved("https://bark.example"))
        XCTAssertEqual(AddressDraft.evaluate("https://api.day.app"), .saved("https://api.day.app"))
        if case let .rejected(message) = AddressDraft.evaluate("file:///tmp/bark") {
            XCTAssertTrue(message.contains("不会发起网络请求"))
        } else {
            XCTFail("file URL must be rejected")
        }
        let saved = CapabilityStatement(serverAddress: "https://bark.example", notificationPermission: "已允许")
        XCTAssertFalse(saved.connected)
        XCTAssertFalse(saved.verified)
        XCTAssertFalse(saved.apnsReady)
        XCTAssertEqual(saved.serverLine, "服务器：已保存地址，未注册，未连接，未验证")
        let empty = CapabilityStatement(serverAddress: "", notificationPermission: "未询问")
        XCTAssertEqual(empty.serverLine, "服务器：未配置")
        XCTAssertFalse(CapabilityStatement.apnsLine.contains("已向 APNs 注册"))
        XCTAssertTrue(CapabilityStatement.apnsLine.contains("未向 APNs 注册"))
    }

    func testLegacyKeysAreNotImported() {
        let imported = KeyIsolation.independentKey(in: [
            "me.fin.bark.key": "ios-key",
            "key": "another-key",
            "me.fin.bark.servers": "[]"
        ])
        XCTAssertNil(imported)
        XCTAssertEqual(
            KeyIsolation.independentKey(in: [KeyIsolation.independentKeyDefaultsKey: "  mac-key  "]),
            "mac-key"
        )
        XCTAssertNil(KeyIsolation.independentKey(in: [KeyIsolation.independentKeyDefaultsKey: "   "]))
        for legacy in KeyIsolation.ignoredLegacyKeys {
            XCTAssertFalse(AppStorageKeys.written.contains(legacy))
        }
        XCTAssertFalse(AppStorageKeys.written.contains(KeyIsolation.independentKeyDefaultsKey))
    }

    func testCopyURLRequiresIndependentKey() {
        XCTAssertNil(PushLink.copyableURL(baseAddress: "https://bark.example", independentKey: nil))
        XCTAssertNil(PushLink.copyableURL(baseAddress: "https://bark.example", independentKey: "  "))
        XCTAssertNil(PushLink.copyableURL(baseAddress: "", independentKey: "mac-key"))
        XCTAssertNil(PushLink.copyableURL(baseAddress: "notaurl", independentKey: "mac-key"))
        XCTAssertEqual(
            PushLink.copyableURL(baseAddress: "https://bark.example/", independentKey: "mac key"),
            "https://bark.example/mac%20key"
        )
    }

    func testDockHidesOnlyWhenStatusItemExists() {
        XCTAssertFalse(DockPolicy.hidesDock(preferenceHidden: true, statusItemInstalled: false))
        XCTAssertTrue(DockPolicy.hidesDock(preferenceHidden: true, statusItemInstalled: true))
        XCTAssertFalse(DockPolicy.hidesDock(preferenceHidden: false, statusItemInstalled: true))
        XCTAssertFalse(DockPolicy.hidesDock(preferenceHidden: false, statusItemInstalled: false))
    }

    func testWindowDefaultsStayResident() {
        XCTAssertTrue(WindowPolicy.defaultStayResidentAfterLastWindowClosed)
        XCTAssertTrue(WindowPolicy.defaultShowDockIcon)
        XCTAssertFalse(WindowPolicy.terminateAfterLastWindowClosed(stayResident: true))
        XCTAssertTrue(WindowPolicy.terminateAfterLastWindowClosed(stayResident: false))
    }

    func testMenuSummaryOmitsBodyAndKey() {
        let line = PrivacySummary.menuLine(
            title: "构建完成",
            body: "secret-body-value",
            deviceKey: "secret-device-key"
        )
        XCTAssertEqual(line, "最近消息：构建完成")
        XCTAssertFalse(line.contains("secret-body-value"))
        XCTAssertFalse(line.contains("secret-device-key"))
        XCTAssertEqual(
            PrivacySummary.menuLine(title: "   ", body: "secret-body-value", deviceKey: "k"),
            "最近消息：一条通知"
        )
        let long = String(repeating: "测", count: 50)
        let truncated = PrivacySummary.menuLine(title: long, body: "body", deviceKey: nil)
        XCTAssertEqual(truncated.count, "最近消息：".count + 40)
    }

    func testPermissionLineDoesNotClaimPush() {
        let line = NotificationPermissionCopy.permissionLine(statusName: "已允许")
        XCTAssertTrue(line.contains("已允许"))
        XCTAssertTrue(line.contains("未连接"))
        XCTAssertTrue(line.contains("未验证"))
        XCTAssertFalse(line.contains("已连接"))
        XCTAssertFalse(line.contains("APNs 可用"))
    }

    func testHTTPShapeIsMacOSAndUnusedByNetworkPolicy() {
        let query = BarkHTTPShape.registerQuery(deviceToken: "abc", existingKey: " ")
        XCTAssertEqual(BarkHTTPShape.registerPath, "/register")
        XCTAssertEqual(query["devicetoken"], "abc")
        XCTAssertEqual(query["device_type"], "macos")
        XCTAssertNil(query["key"])
        let withKey = BarkHTTPShape.registerQuery(deviceToken: "abc", existingKey: "own-key")
        XCTAssertEqual(withKey["key"], "own-key")
        XCTAssertFalse(RegistrationPolicy.networkRegistrationEnabled)
    }
}
