# 起因

由于项目中用到realm，遇到一个问题：由于realm没有不支持自增长索引，且如果没有存储数据插入的时间的话，没有办法根据数据插入的顺序进行排序（或者是我没找到方法）。
虽然直接查询所有数据，给出来的结果的顺序 貌似 是按照数据插入的顺序排序的，其实不然。没有指定排序方式的话，查出来的Result结果集realm是不保证有序的。
所以出现的一个问题，如果对结果集中的元素进行删除，有可能导致数据顺序混乱。如果加了数据集监听，则回调的参数看起来很奇怪。
从而导致异常或crash。比如数据集跟TableView的DataSource关联的话。

这个repo原本是为了给realm提issue作示例用的，相应issue https://github.com/realm/realm-cocoa/issues/6037#issue-391659108

# 后续

我的解决方式是

给Object增加一个子类SortableObject，由此类派生出去的类，在插入数据库的时候自带一个递增的index，并提供一些函数和realm的扩展方法，以方便的解决realm无法根据插入顺序进行排序问题。

1.把原先继承于Object的类改为继承于SortableObject

2.如需从旧数据迁移，则把realm的配置中的版本号schemaVersion提高：config.schemaVersion = 2

3.注册继承于SortableObject的类型：SortableObjectMigrationTool.shared.register(class: Dog.self)

4.设置迁移工具，并尝试触发数据迁移（如版本号schemaVersion没升高则不会触发）：SortableObjectMigrationTool.shared.setupAndMigration(for: config)

