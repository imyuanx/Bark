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
        XCTAssertFalse(RegistrationPolicy.launchesRegistrationAutomatically)
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
        let saved = DeliveryStages(
            permissionName: "已允许",
            apns: .notRequested,
            backend: .notRequested,
            delivery: .notObserved
        )
        XCTAssertFalse(saved.claimsConnected)
        XCTAssertFalse(saved.claimsDelivered)
        XCTAssertTrue(saved.permissionLine.contains("只表示本机授权"))
        XCTAssertTrue(saved.apnsLine.contains("未请求"))
        XCTAssertTrue(saved.backendLine.contains("没有发送 /register"))
        XCTAssertTrue(saved.deliveryLine.hasPrefix("服务端投递：未观察"))
        XCTAssertFalse(saved.apnsLine.contains("已连接"))
        XCTAssertFalse(saved.deliveryLine.contains("投递成功"))
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
        XCTAssertFalse(RegistrationPolicy.launchesRegistrationAutomatically)
    }

    func testDefaultGatesDoNotSend() {
        var calls = 0
        let outcome = RegistrationAttempt.perform(
            RegistrationGate.Input(
                serverAddress: "https://bark.example",
                userEnabled: false,
                backendMarkedCompatible: false,
                macKey: nil,
                deviceToken: nil
            )
        ) { _ in
            calls += 1
        }
        XCTAssertEqual(outcome, .blockedDisabled)
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(
            APNsTokenPolicy.evaluate(APNsTokenPolicy.Input(userEnabled: false, signingAcknowledged: false)),
            .notRequested
        )
    }

    func testOfficialServerStaysBlockedWhenEnabled() {
        var calls = 0
        let outcome = RegistrationAttempt.perform(
            RegistrationGate.Input(
                serverAddress: "https://api.day.app",
                userEnabled: true,
                backendMarkedCompatible: true,
                macKey: "fresh-mac-key",
                deviceToken: "abc"
            )
        ) { _ in
            calls += 1
        }
        XCTAssertEqual(outcome, .blockedOfficialServer)
        XCTAssertEqual(calls, 0)
    }

    func testAllowedRequestOmitsLegacyKeyAndCreatesANewMacKey() {
        var sent: RegistrationRequest?
        let outcome = RegistrationAttempt.perform(
            RegistrationGate.Input(
                serverAddress: "https://bark.example/",
                userEnabled: true,
                backendMarkedCompatible: true,
                macKey: nil,
                deviceToken: "abc"
            )
        ) { request in
            sent = request
        }
        guard case .allowed = outcome else {
            return XCTFail("expected an allowed request")
        }
        XCTAssertEqual(sent?.query["device_type"], "macos")
        XCTAssertEqual(sent?.query["devicetoken"], "abc")
        XCTAssertNil(sent?.query["key"])
        XCTAssertEqual(sent?.url.absoluteString, "https://bark.example/register")
        XCTAssertNil(MacKeyStore.keyFromRegistration("ios-key", legacyValues: ["ios-key"]))
        let data = Data("{\"data\":{\"key\":\"new-mac-key\"}}".utf8)
        XCTAssertEqual(RegistrationResponse.macKey(from: data, legacyValues: ["ios-key"]), "new-mac-key")
        XCTAssertNil(RegistrationResponse.macKey(from: data, legacyValues: ["new-mac-key"]))
    }

    func testCompatibleBackendStillNeedsAToken() {
        let outcome = RegistrationGate.evaluate(
            RegistrationGate.Input(
                serverAddress: "https://bark.example",
                userEnabled: true,
                backendMarkedCompatible: true,
                macKey: "own-key",
                deviceToken: "  "
            )
        )
        XCTAssertEqual(outcome, .blockedNoDeviceToken)
        let apns = APNsTokenPolicy.evaluate(
            APNsTokenPolicy.Input(userEnabled: true, signingAcknowledged: false)
        )
        XCTAssertEqual(apns, .blockedUnsigned)
    }
}
