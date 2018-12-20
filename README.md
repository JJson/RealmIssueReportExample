# 起因

由于项目中用到realm，遇到一个问题：由于realm没有支持自增长索引，且如果没有存储数据插入的时间的话，没有办法根据数据插入的顺序进行排序（或者是我没找到方法）。

如：
1.现数据库中按顺序插入6条数据，分别为 A, B, C, D, E, F

2.查询所有数据，给出的结果是A, B, C, D, E, F

3.删除数据C，然后再查询，结果是A, B, F, D, E

realm对这种未指定顺序的处理方式是，删掉C，然后取最后一个数据F，插入C原来的位置。realm这么处理，而不是C后面的数据顺位往前移，应该是为了避免C和F之间的操作。

但是实际应用中，对以Realm的查询结果集Result作为DataSource的table来说，这样的方式可能显得很奇怪。想象一下，我删除中间某条数据，结果最后一条数据占了原先删除掉的那条数据的位置，而不是后面的各条数据往前挪一位，是不是很奇怪？但是列表用到的数据可能没有适合用作顺序索引的列，比如时间什么的。

所以可能需要根据插入数据库的先后来展示各条数据，删除其中某条数据，不影响其他数据间的先后顺序，我的做法是对这个表（在Realm里一个对象类型对应一张表）增加一列index作为索引，在插入时对index进行+1操作。

为了让我原来的应用代码改动尽量的小，所以我给Object增加一个子类SortableObject，由此类派生出去的类，在插入数据库的时候自带一个递增的index，并提供一些函数和realm的扩展方法，来方便的索引的生成和整理，以及旧数据的迁移。


这个repo原本是为了给realm提issue作示例用的，相应issue https://github.com/realm/realm-cocoa/issues/6037#issue-391659108

# 使用方式


1.把原先继承于Object的类改为继承于SortableObject

2.如需从旧数据迁移，则把realm的配置中的版本号schemaVersion提高：config.schemaVersion = 2

3.注册继承于SortableObject的类型：SortableObjectMigrationTool.shared.register(class: Dog.self)

4.设置迁移工具，并尝试触发数据迁移（如版本号schemaVersion没升高则不会触发）：SortableObjectMigrationTool.shared.setupAndMigration(for: config)

