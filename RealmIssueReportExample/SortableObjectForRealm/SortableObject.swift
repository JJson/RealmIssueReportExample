//
//  SortableObject.swift
//  RealmIssueReportExample
//
//  Created by linjj on 2018/12/18.
//  Copyright © 2018 linjj. All rights reserved.
//

import RealmSwift

public class SortableObject: Object {
    @objc dynamic var sortIndex = -1
    
    /// 给Dog的索引进行整理，例如，经过随机删除部分数据后，剩下的数据中可能索引值间隔不紧凑，使用该方法重新设置紧凑的索引值
    ///
    /// - Parameter reverse: 是否逆序
    class func organizeIndex(forConfiguration configuration: Realm.Configuration, _ reverse: Bool = false) {
    
        guard let realm = try? Realm(configuration: configuration) else { return }
        let result = realm.objects(self).sorted(byKeyPath: "sortIndex", ascending: true)
        let count = result.count
        try? realm.write {
            if reverse {
                for (index, item) in result.enumerated() {
                    item.sortIndex = count - 1 - index
                }
            } else {
                for (index, item) in result.enumerated() {
                    item.sortIndex = index
                }
            }
            
        }
        IndexManager.shared.providerForClassName(self.className())?.curUnusedIndex = count
    }
    
    /// 根据migration，由原来的Object转为SortableObject时，补全索引
    ///
    /// - Parameter migration: 这个入参为Realm.Configuration的migrationBlock的参数
    class func doMigration(with migration: Migration) {
        let className = self.className()
        if let indexProvider = IndexManager.shared.providerForClassName(className) {
            migration.enumerateObjects(ofType: className, { (oldObject, newObject) in
                
                newObject!["sortIndex"] = indexProvider.curUnusedIndex
                indexProvider.increase()
            })
        } else {
            print("err")
        }
    }
    

    
}


extension Realm {
    public func add(sortableObject: SortableObject, update: Bool = false) {
        let t = type(of: sortableObject)
        if let indexProvider = IndexManager.shared.providerForClassName(t.className()) {
            
            var existBeforeAdd = false
            if let primaryKey = t.primaryKey(),
                let objInDB  = object(ofType: t, forPrimaryKey: primaryKey) {
                // 数据插入前已存在,则使用原来的sortIndex
                existBeforeAdd = true
                sortableObject.sortIndex = objInDB.sortIndex
            } else {
                // 数据插入前不存在,则使用新的未使用的sortIndex
                sortableObject.sortIndex = indexProvider.curUnusedIndex
            }
            add(sortableObject, update: update)
            
            if !existBeforeAdd {// 数据插入前不存在，则索引增长
                indexProvider.increase()
            }
            
        }
    }
    public func objectsSorted<Element: Object>(_ type: Element.Type, _ ascending: Bool = true) -> Results<Element> {
        return objects(type).sorted(byKeyPath: "sortIndex", ascending: ascending)
    }
}
