//
//  AppLog.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import protocol TangemExpress.Logger
import protocol TangemVisa.VisaLogger
import protocol TangemStaking.Logger

class AppLog {
    static let shared = AppLog()

    let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        var loggers: [TangemSdkLogger] = [fileLogger]

        if AppEnvironment.current.isDebug {
            loggers.append(ConsoleLogger())
        }

        return .custom(
            logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
            loggers: loggers
        )
    }

    func configure() {
        Log.config = sdkLogConfig
        fileLogger.removeLogFileIfNeeded()
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        OSLog.debug(message(), category: .custom("Common"))
    }

    // TODO: Andrey Fedorov - Get rid of this method and pass file/line as arguments to `debug` (IOS-6440)
    func debugDetailed<T>(file: StaticString = #fileID, line: UInt = #line, _ message: @autoclosure () -> T) {
        Log.debug("\(file):\(line): \(message())")
    }

    func error(_ error: Error) {
        self.error(error: error, params: [:])
    }

    func logAppLaunch(_ currentLaunch: Int) {
        let sessionMessage = "New session.\nSession id: \(AppConstants.sessionId)"
        let launchNumberMessage = "Current launch number: \(currentLaunch)"
        let deviceInfoMessage = "\(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", "))"
        debug("\(sessionMessage)\n\(launchNumberMessage)\n\(deviceInfoMessage)")
    }
}

struct TangemExpressLogger: TangemExpress.Logger {
    func debug<T>(_ message: @autoclosure () -> T) {
        OSLog.debug(message(), category: .express)
    }

    func error(_ error: any Error) {
        OSLog.error(error.localizedDescription, category: .express)
    }
}

extension AppLog: VisaLogger {}

struct TangemStakingLogger: TangemStaking.Logger {
    public func debug<T>(_ message: @autoclosure () -> T) {
        OSLog.debug(message(), category: .staking)
    }

    public func error(_ error: any Error) {
        OSLog.error(error.localizedDescription, category: .staking)
    }
}
