//
//  ViewController.swift
//  RealmIssueReportExample
//
//  Created by linjj on 2018/12/17.
//  Copyright © 2018 linjj. All rights reserved.
//

import UIKit
import RealmSwift

class Dog: SortableObject {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    override static func primaryKey() -> String? {
        return "name"
    }
}



class ViewController: UIViewController {
    var dogs = [Dog]()
    
    
    
    var token: NotificationToken?
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        var config = Realm.Configuration()
        
        
        config.shouldCompactOnLaunch = { totalBytes, usedBytes in
            // totalBytes refers to the size of the file on disk in bytes (data + free space)
            // usedBytes refers to the number of bytes used by data in the file
            
            // Compact if the file is over 100MB in size and less than 80% 'used'
            let oneHundredMB = 100 * 1024 * 1024
            return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.8
        }
        config.schemaVersion = 2 //增长版本号
        //设置和出发旧数据迁移
        SortableObjectMigrationTool.shared.register(class: Dog.self)
        SortableObjectMigrationTool.shared.setupAndMigration(for: config)

//        initData()
        query()
    }

    @IBAction func deleteAction(_ sender: Any) {
        guard dogs.count > 0 else {
            return
        }
        let realm = try! Realm()
        try! realm.write {
            let index = Int(arc4random()) % dogs.count
            let randomDog = dogs[index]
            print("delete index: \(index),value:\(randomDog.age)")
            realm.delete(randomDog)
            dogs.remove(at: index)
        }
    }
    
    @IBAction func addAction(_ sender: Any) {
        do {
            let realm = try Realm()
            
            try realm.write {
                var countAdded = 0
                var existCountTotal = 0
                var existCount = 0
                
                print("begin:\(Date())")
                while existCount < 1000000 {//连续因为重复而插入失败100000次，则终止循环
                    autoreleasepool(invoking: { () -> Void in
                        let i = Int(arc4random()%1000000)
                        if let _ = realm.object(ofType: Dog.self, forPrimaryKey: "name\(i)") {
                            existCount += 1
                        } else {
                            let dog = Dog()
                            dog.name = "name\(i)"
                            dog.age = i
                            realm.add(sortableObject: dog, update: false)
                            dogs.append(dog)
                            countAdded += 1
                            existCountTotal += existCount
                            existCount = 0
                        }
                    })
                    
                }
                existCountTotal += existCount
                print("end:\(Date())")
                print("add object count: \(countAdded), total count: \(realm.objects(Dog.self).count), select exist dup count: \(existCountTotal)")
            }
        } catch {
            fatalError("\(error)")
        }
    }
    @IBAction func organizeAction(_ sender: Any) {
    }
    
    
    func query() {
        let realm = try! Realm()
        let result = realm.objectsSorted(Dog.self)
        dogs = Array(result)
        token = result.observe {[weak self] (change) in
            guard let strongSelf = self else { return }
            switch change {
                
            case .initial(_):
//                let dgs = Array(result)
//                let str = dgs.map({ (dog) -> String in
//                    return "\(dog.age)"
//                }).joined(separator: ",")
//                print("init cur data:\(str)")
                break
            case .update(_, let deletions, let insertions, let modifications):
                print("deletions: \(deletions.count), insertions: \(insertions.count), modifications: \(modifications.count)")
//                let dgs = Array(result)
//                let str = dgs.map({ (dog) -> String in
//                    return "\(dog.age)"
//                }).joined(separator: ",")
//                print("cur data:\(str)")
            
                
                //update table view
                strongSelf.tableView.beginUpdates()
                if deletions.count > 0 {
                    let indexPaths = deletions.map({ (value) -> IndexPath in
                        IndexPath(row: value, section: 0)
                    })
                    strongSelf.tableView.deleteRows(at: indexPaths, with: .automatic)
                }
                if insertions.count > 0 {
                    let indexPaths = insertions.map({ (value) -> IndexPath in
                        IndexPath(row: value, section: 0)
                    })
                    strongSelf.tableView.insertRows(at: indexPaths, with: .automatic)
                }
                if modifications.count > 0 {
                    let indexPaths = modifications.map({ (value) -> IndexPath in
                        IndexPath(row: value, section: 0)
                    })
                    strongSelf.tableView.reloadRows(at: indexPaths, with: .automatic)
                }
                
                strongSelf.tableView.endUpdates()
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
    
    func initData() {
        do {
            let realm = try Realm()
            
            try realm.write {
                for i in 0..<50 {
                    let dog = Dog()
                    dog.name = "name\(i)"
                    dog.age = i
//                    realm.add(dog, update: true)
                    realm.add(sortableObject: dog, update: true)
                }
            }
        } catch {
            fatalError("\(error)")
        }
        
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let dog = dogs[indexPath.row]
        cell.textLabel?.text = "name:\(dog.name) age:\(dog.age) index: \(dog.sortIndex)"
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    
}
