# 起因

由于项目中用到realm，遇到一个问题：由于realm没有支持自增长索引，且如果没有存储数据插入的时间的话，没有办法根据数据插入的顺序进行排序（或者是我没找到方法）。

如：
1.现数据库中按顺序插入6条数据，分别为 A, B, C, D, E, F

2.查询所有数据，给出的结果是A, B, C, D, E, F

3.删除数据C，然后再查询，结果是A, B, F, D, E

realm对这种未指定顺序的处理方式是，删掉C，然后取最后一个数据F，插入C原来的位置。realm这么处理，而不是C后面的数据顺位往前移，应该是为了避免C和F之间的操作。但是实际应用中，可能需要根据插入数据库的先后来展示各条数据，删除其中某条数据，不影响其他数据间的先后顺序，常用的做法是对这个表（在Realm里一个对象类型对应一张表）增加一列index作为索引。所以我封装了一个基类，以及一些工具类，来方便的索引的生成和整理，以及旧数据的迁移。对原来应用中的业务代码改动尽量的小。


这个repo原本是为了给realm提issue作示例用的，相应issue https://github.com/realm/realm-cocoa/issues/6037#issue-391659108

# 后续

我的解决方式是

给Object增加一个子类SortableObject，由此类派生出去的类，在插入数据库的时候自带一个递增的index，并提供一些函数和realm的扩展方法，以方便的解决realm无法根据插入顺序进行排序问题。使用方法如下：

1.把原先继承于Object的类改为继承于SortableObject

2.如需从旧数据迁移，则把realm的配置中的版本号schemaVersion提高：config.schemaVersion = 2

3.注册继承于SortableObject的类型：SortableObjectMigrationTool.shared.register(class: Dog.self)

4.设置迁移工具，并尝试触发数据迁移（如版本号schemaVersion没升高则不会触发）：SortableObjectMigrationTool.shared.setupAndMigration(for: config)

