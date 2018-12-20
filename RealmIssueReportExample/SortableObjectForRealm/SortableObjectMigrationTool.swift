//
//  SortableObjectMigrationTool.swift
//  RealmIssueReportExample
//
//  Created by linjj on 2018/12/20.
//  Copyright © 2018 linjj. All rights reserved.
//

import Foundation
import RealmSwift

class SortableObjectMigrationTool {
    static let shared = SortableObjectMigrationTool()
    var supportStartDBVersion = 1
    var registeredClasses = [AnyClass]()
    func register(class cls: SortableObject.Type) {
        registeredClasses.append(cls)
    }
    
    /// 给对应的config设置迁移回调
    ///
    /// - Parameter config: Realm.Configuration
    fileprivate func setMigration( with config: inout Realm.Configuration) {
        config.migrationBlock = {[weak self] (migration, oldSchemaVersion) in
            guard let strongSelf = self else { return }
            if oldSchemaVersion < strongSelf.supportStartDBVersion {
                IndexManager.shared.migrated = true
                for item in strongSelf.registeredClasses {
                    if let cls = item as? SortableObject.Type {
                        cls.doMigration(with: migration)
                    }
                }
            }
        }
    }
    
    /// 初始化，包括设置数据迁移执行闭包，初始化索引管理器，注册需要使用到索引管理器的类
    /// 并尝试触发迁移，migrationBlock中有检查是否需要迁移的判断
    /// - Parameter config: Realm.Configuration
    func setupAndMigration(for config: Realm.Configuration) {
        var configForMigration = config
        setMigration(with: &configForMigration)
        IndexManager.shared.setup(forConfiguration: configForMigration)//初始化自增长索引管理器，可传入configuration，默认为Realm.Configuration.defaultConfiguration
        // 在索引管理器中注册需要使用到索引管理器的类
        for item in registeredClasses {
            if let cls = item as? SortableObject.Type {
                IndexManager.shared.register(cls.className())
            }
        }
        
        let _ = try! Realm(configuration: configForMigration)//调用Realm初始化方法，尝试触发旧数据迁移
        //如果发生迁移，则对索引进行整理
        if IndexManager.shared.migrated {
            for item in registeredClasses {
                if let cls = item as? SortableObject.Type {
                    cls.organizeIndex(forConfiguration: configForMigration, true)//给对应的索引进行整理，传入true为逆序
                }
            }
        }
        
    }
}
