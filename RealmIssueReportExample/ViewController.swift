//
//  ViewController.swift
//  RealmIssueReportExample
//
//  Created by linjj on 2018/12/17.
//  Copyright © 2018 linjj. All rights reserved.
//

import UIKit
import RealmSwift

class Dog: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    override static func primaryKey() -> String? {
        return "name"
    }
}


class ViewController: UIViewController {
    var dogs = [Dog]()
    var token: NotificationToken?
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        query()
    }

    @IBAction func deleteAction(_ sender: Any) {
        guard dogs.count > 0 else {
            return
        }
        let realm = try! Realm()
        try! realm.write {
            let index = Int(arc4random()) % dogs.count
            print("delete index: \(index)")
            let randomDog = dogs[index]
            realm.delete(randomDog)
            dogs.remove(at: index)
        }
    }
    func query() {
        let realm = try! Realm()
        let result = realm.objects(Dog.self).filter("age > 3")
        dogs = Array(result)
        token = result.observe { (change) in
            switch change {
                
            case .initial(_):
                break
            case .update(_, let deletions, let insertions, let modifications):
                print("deletions: \(deletions), insertions: \(insertions), modifications: \(modifications)")
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
                    realm.create(Dog.self, value: ["name\(i)",i], update: true)
                }
            }
        } catch {
            fatalError("\(error)")
        }
        
    }
}

