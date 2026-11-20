//
//  SharedStore.swift
//  todoapp
//
//  アプリとウィジェットで共有するデータの置き場所（App Group）。docs/widgets.md 4.3 参照。
//  - データ（SwiftData）と設定（UserDefaults）を App Group に置く
//  - 以前のデータはアプリの中にあったので、初回だけ App Group へ移す
//

import Foundation
import SwiftData

enum SharedStore {
    /// App Group の名前（アプリとウィジェットの entitlements と同じ）
    nonisolated static let appGroupID = "group.com.yoshiyuki.todoapp"

    /// 保存するモデル
    static let schema = Schema([TodoGroup.self, SubGroup.self, TodoTask.self])

    private static let storeFileName = "default.store"

    /// 設定の保存先（App Group。使えなければ通常の UserDefaults）
    nonisolated static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// App Group の中のデータの場所。App Group が使えなければ nil
    static var sharedStoreURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "Library/Application Support/\(storeFileName)")
    }

    /// 以前の場所（アプリの中）
    static var legacyStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: storeFileName)
    }

    /// アプリとウィジェットが使う ModelContainer。
    /// `migrateLegacyStore` はアプリだけが true にする（ウィジェットは移し替えをしない）。
    static func makeContainer(migrateLegacyStore: Bool) throws -> ModelContainer {
        guard let sharedURL = sharedStoreURL else {
            // App Group が使えない（設定漏れなど）。アプリは今までどおり動かす
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        }
        if migrateLegacyStore {
            moveLegacyStoreIfNeeded(to: sharedURL)
        }
        try? FileManager.default.createDirectory(at: sharedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let configuration = ModelConfiguration(schema: schema, url: sharedURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// 以前のデータを App Group へ 1 回だけ写す。
    /// - App Group 側にすでにデータがあれば何もしない（二重にしない）
    /// - 写すのに失敗したら、写しかけたものを消す（次の起動でやり直す）
    /// - 元のファイルは消さずに残す（万一のときの控え）
    static func moveLegacyStoreIfNeeded(from legacyURL: URL = legacyStoreURL, to sharedURL: URL,
                                        fileManager: FileManager = .default) {
        // URL の path() は空白を %20 にしてしまうので、percentEncoded: false で比べる
        guard !fileManager.fileExists(atPath: sharedURL.path(percentEncoded: false)),
              fileManager.fileExists(atPath: legacyURL.path(percentEncoded: false)) else { return }

        try? fileManager.createDirectory(at: sharedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        // SQLite は本体と -wal・-shm の 3 つで 1 組
        let suffixes = ["", "-wal", "-shm"]
        var copied: [URL] = []
        do {
            for suffix in suffixes {
                let source = URL(filePath: legacyURL.path(percentEncoded: false) + suffix)
                let destination = URL(filePath: sharedURL.path(percentEncoded: false) + suffix)
                guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
                try fileManager.copyItem(at: source, to: destination)
                copied.append(destination)
            }
        } catch {
            for url in copied { try? fileManager.removeItem(at: url) }
        }
    }

    /// 設定（テーマなど）を、通常の UserDefaults から App Group へ 1 回だけ写す
    static func migrateLegacyDefaults(keys: [String]) {
        let shared = defaults
        let migratedKey = "didMigrateDefaultsToAppGroup"
        guard shared !== UserDefaults.standard, !shared.bool(forKey: migratedKey) else { return }
        for key in keys {
            if shared.object(forKey: key) == nil, let value = UserDefaults.standard.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }
        shared.set(true, forKey: migratedKey)
    }
}

/// ウィジェットの種類（再読み込みの指定に使う）
enum WidgetKinds {
    static let tasks = "TaskListWidget"
    static let lockList = "LockTaskListWidget"
    static let lockProgress = "LockProgressWidget"
}

/// ウィジェットからアプリを開くときの URL（todoapp://task/<id> など）
nonisolated enum AppLink: Equatable {
    case task(UUID)
    case group(UUID)
    case allGroups

    static let scheme = "todoapp"

    var url: URL {
        switch self {
        case .task(let id): URL(string: "\(Self.scheme)://task/\(id.uuidString)")!
        case .group(let id): URL(string: "\(Self.scheme)://group/\(id.uuidString)")!
        case .allGroups: URL(string: "\(Self.scheme)://all")!
        }
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme, let host = url.host() else { return nil }
        let idText = url.pathComponents.dropFirst().first
        switch host {
        case "all": self = .allGroups
        case "task":
            guard let idText, let id = UUID(uuidString: idText) else { return nil }
            self = .task(id)
        case "group":
            guard let idText, let id = UUID(uuidString: idText) else { return nil }
            self = .group(id)
        default: return nil
        }
    }
}
