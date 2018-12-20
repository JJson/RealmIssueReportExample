//
//  IndexManager.swift
//  RealmIssueReportExample
//
//  Created by linjj on 2018/12/18.
//  Copyright © 2018 linjj. All rights reserved.
//

import Foundation
import RealmSwift

class IndexObject: Object {
    @objc dynamic var index = 0
    @objc dynamic var objectName = ""
    
    override static func primaryKey() -> String? {
        return "objectName"
    }
    
}

class IndexProvider {
    var indexProvider: IndexObject
    init(withObjectName name: String, mainDBConfiguration configuration: RealmSwift.Realm.Configuration) throws {

        guard let mainDataBasePath = configuration.fileURL?.path else {
            throw NSError(domain: "com.IndexProvider.Init", code: -9992, userInfo: [NSLocalizedDescriptionKey:"main db not exist"])
        }
        var tmp = mainDataBasePath.components(separatedBy: "/")
        tmp.removeLast()
        tmp.append("PCIdx.realm")
        let indexProviderDBPath = tmp.joined(separator: "/")
        let config = Realm.Configuration(fileURL: URL(fileURLWithPath: indexProviderDBPath))
        let realm = try Realm(configuration: config)
        if let result = realm.object(ofType: IndexObject.self, forPrimaryKey: name) {
            indexProvider = result
        } else {
            let provider = IndexObject()
            provider.objectName = name
            try realm.write {
                realm.add(provider, update: true)
            }
            indexProvider = provider
        }
    }
    
    var curUnusedIndex: Int {
        get {
            return indexProvider.index
        }
        set {
            if let realm = indexProvider.realm {
                try? realm.write {
                    indexProvider.index = newValue
                }
            } else {
                indexProvider.index = newValue
            }
            
        }
    }
    
    func increase() {
        curUnusedIndex += 1
    }
    
}

class IndexManager {
    static let shared = IndexManager()
    var lastConfig = Realm.Configuration.defaultConfiguration
    var providerDic = [String:IndexProvider]() // key 为className，Value为对于的Provider
    var migrated = false
    
    func providerForClassName(_ className: String) -> IndexProvider? {
        return providerDic[className]
    }
    
    
    /// 注册使用到索引的类名
    ///
    /// - Parameter className: 类名
    func register(_ className: String) {
        if let value = try? IndexProvider(withObjectName: className, mainDBConfiguration: lastConfig) {
            providerDic[className] = value
        }
    }
    
    /// 根据Realm配置，来初始化索引管理器，设置各索引的Provider
    ///
    /// - Parameter configuration: realm的配置，如不传，默认为当前的Realm.Configuration.defaultConfiguration
    func setup(forConfiguration configuration: RealmSwift.Realm.Configuration? = nil) {
        
        var config = Realm.Configuration.defaultConfiguration
        if configuration != nil {
            config = configuration!
            lastConfig = config
        }
        if config.fileURL != lastConfig.fileURL {
            var newProviderDic = [String:IndexProvider]()
            for (key,_) in providerDic {
                if let value = try? IndexProvider(withObjectName: key, mainDBConfiguration: config) {
                    newProviderDic[key] = value
                }
            }
            providerDic = newProviderDic
//            print("new")
        } else {
//            print("same")
        }
    }
}
