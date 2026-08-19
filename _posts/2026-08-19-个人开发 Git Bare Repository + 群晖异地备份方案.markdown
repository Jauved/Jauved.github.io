---
layout: post
title: "个人开发 Git Bare Repository + 群晖异地备份方案"
categories: [Git, NAS]
tags: Git BareRepository Synology 群晖 NAS HyperBackup 备份 灾难恢复
math: true


---

# 个人开发 Git Bare Repository + 群晖异地备份方案

## 1. 目标

当前开发环境采用:

```text
开发机
   ↓ git push
主 NAS
   ↓
Bare Git Repository
```

计划增加第二台异地 NAS, 主要解决以下问题:

1. 主 NAS 物理损坏.
2. 主 NAS 硬盘或文件系统损坏.
3. Git 仓库被误删.
4. 数据发生损坏后较晚才被发现.
5. 主 NAS 所在地点发生火灾、进水、雷击等整体事故.

当前阶段的首要目标是:

> 保证 Git 仓库数据可以可靠恢复.

不是:

> 主 NAS 故障后, 第二台 NAS 必须立即接管 Git 服务.

后者属于更进一步的灾难恢复需求, 后续再讨论.

------

# 2. 当前建议架构

采用群晖 Hyper Backup:

```text
开发机
   │
   │ git push
   ▼
NAS A
主 NAS
│
├── GitBareRepos/
│   ├── ProjectA.git
│   ├── ProjectB.git
│   ├── ShaderLibrary.git
│   └── ...
│
└── Hyper Backup
        │
        │ 定时增量备份
        ▼
NAS B
异地备份 NAS
│
└── Hyper Backup Vault
        │
        └── Hyper Backup Backup Repository
```

职责明确划分为:

```text
开发机
    = 工作副本 + Local Git Repository

NAS A
    = 日常使用的中央 Bare Git Repository

NAS B
    = 异地历史备份
```

NAS B 不作为日常 Git Server 使用.

------

# 3. 为什么不直接做 NAS A → NAS B 实时同步

实时同步解决的是:

> 保持两个位置的数据状态一致.

备份解决的是:

> 即使当前状态已经错误, 仍然能够恢复过去的正确状态.

例如:

```text
NAS A

ProjectA.git
ProjectB.git
ProjectC.git
```

如果误删:

```text
ProjectB.git
```

普通同步可能变成:

```text
NAS A 删除 ProjectB.git
        ↓
同步
        ↓
NAS B 同样删除 ProjectB.git
```

结果是:

```text
两个 NAS 都正确地保存了错误状态.
```

对于备份系统来说, 这是不可接受的.

------

# 4. Hyper Backup 的核心价值

Hyper Backup 保存的不只是:

```text
当前文件
```

而是:

```text
当前文件状态
+
历史版本
```

例如:

```text
Version 1
    周一

Version 2
    周二

Version 3
    周三

Version 4
    周四
```

假设周四发生误删除:

```text
ProjectB.git
```

仍然可以选择:

```text
Version 3
```

恢复删除之前的数据.

因此:

> 备份不是复制现在, 而是保存过去.

------

# 5. Hyper Backup 是否每次完整复制

不是.

可以从使用层面将其近似理解为:

```text
第一次备份
    ↓
建立完整基底

后续备份
    ↓
保存新增或变化的数据
+
保存对应版本的状态信息
```

例如:

```text
Version 1
100 GB

Version 2
新增 / 修改 2 GB

Version 3
新增 / 修改 1 GB
```

不会简单变成:

```text
100 GB
+
100 GB
+
100 GB

= 300 GB
```

而更接近:

```text
初始数据
+
后续变化数据
+
版本索引 / 元数据
```

因此 Hyper Backup 属于:

> 增量、多版本备份系统.

------

# 6. Hyper Backup 和 Git 的关系

可以使用一个便于理解的类比:

```text
Git Repository
    = 保存代码的历史

Hyper Backup
    = 保存整个 Git Repository 文件状态的历史
```

因此从使用角度看, Hyper Backup 有一点类似:

> Git 仓库外面再增加一层版本历史.

但二者并不相同.

Git 理解:

```text
Commit
Branch
Tag
Tree
Blob
Merge
```

Hyper Backup 不理解这些 Git 语义.

对于 Hyper Backup 来说:

```text
ProjectA.git/
```

只是普通文件和目录.

所以更准确的描述是:

```text
Git
    = 源代码版本管理

Hyper Backup
    = 文件 / 数据备份与版本管理
```

------

# 7. 为什么 Hyper Backup 不让 NAS B 直接接管

这是有意的设计取舍.

两个系统解决的是不同问题:

```text
Hyper Backup

目标:
数据保护优先

特点:
历史版本
增量备份
压缩
去重
完整性检查
独立备份库

代价:
恢复之前不能直接作为原始文件使用
```

另一类方案则是:

```text
Replication

目标:
快速恢复服务优先

特点:
NAS B 保存接近可直接使用的数据状态

优势:
NAS A 故障后可以更快接管
```

可以概括为:

```text
Backup-first
    ↓
Hyper Backup

Recovery-first
    ↓
Replication
```

------

# 8. NAS A 物理损坏后的恢复流程

假设原结构为:

```text
开发机
   ↓
NAS A
GitBareRepos/
   ↓
Hyper Backup
NAS B
Backup Repository
```

NAS A 完全损坏后:

```text
NAS A
  X
```

处理流程:

```text
1. 准备新的 NAS.

2. 安装 DSM.

3. 安装 Hyper Backup.

4. 让新 NAS 能够访问 NAS B.

5. 连接 NAS B 上已有的 Hyper Backup Repository.

6. 选择 NAS A 损坏前的正常恢复点.

7. 恢复 GitBareRepos/.

8. 恢复 Git 使用的用户、权限、SSH 等配置.

9. 开发机重新连接新的 NAS.

10. 执行:
    git fetch
    git push

11. 确认仓库恢复正常.
```

最终结构:

```text
NAS B
Backup Repository
      │
      │ Restore
      ▼
新的 NAS
GitBareRepos/
      │
      ▼
重新成为主 Git Server
```

------

# 9. 最近一次备份之后的 Commit 怎么办

假设:

```text
08:00
Hyper Backup 完成备份

09:00
开发机产生 Commit A

09:01
git push → NAS A

09:30
NAS A 损坏
```

此时 NAS B 只有:

```text
08:00
```

的版本.

但是 Commit A 通常仍然存在于:

```text
开发机的 Local Git Repository
```

因此恢复过程可以是:

```text
NAS B
   ↓
恢复到 08:00

开发机
   ↓
git push

补回 08:00 之后的 Commit
```

Git 本身因此也构成了额外的数据保护层.

------

# 10. 备份 NAS 是否必须远大于主 NAS

不是.

真正应该关注的是:

```text
需要备份的数据量
```

而不是:

```text
NAS A 总容量
```

例如:

```text
NAS A 总容量:
8 TB

实际 Git Repository:
1 TB
```

如果 Hyper Backup 只备份 Git Repository:

```text
需要规划的是这 1 TB 数据的备份空间.
```

而不是必须准备大于 8 TB 的空间.

------

# 11. 备份容量的基本估算

可以粗略理解为:

```text
备份空间

≈ 当前有效数据
+ 被保留的历史变化
+ 未来数据增长
+ 元数据
- 压缩收益
- 去重收益
```

例如:

```text
当前 Git Repository:
2 TB
```

不意味着:

```text
100 个备份版本
=
200 TB
```

因为历史版本不会每次完整复制全部数据.

实际容量取决于数据变化量.

------

# 12. Git Repository 的特殊容量问题

Bare Git Repository 内部存在:

```text
objects/
pack/
```

Git 可能执行:

```text
git gc
git repack
```

例如原本:

```text
pack-A.pack
```

重新打包以后可能变成:

```text
pack-B.pack
```

虽然 Git 仓库的逻辑内容变化不大, 但对于普通备份系统来说可能表现为:

```text
一个大文件被删除
+
一个新的大文件产生
```

因此:

> Git 仓库的备份空间增长速度, 有时会高于代码本身的实际增长速度.

规划备份容量时需要保留额外余量.

初期可以考虑:

```text
实际 Git 数据容量
× 约 2
```

作为一个方便扩展的容量起点.

这不是 Hyper Backup 的硬性要求, 只是容量规划参考.

------

# 13. 推荐的初始备份策略

个人开发可以从比较简单的配置开始:

```text
备份对象:
整个 GitBareRepos/

备份频率:
每几小时一次

版本策略:
启用多版本

完整性检查:
定期执行

备份位置:
物理异地 NAS
```

不需要追求分钟级实时备份.

因为数据实际上存在三层:

```text
开发机 Local Git
        │
        ▼
NAS A Bare Git
        │
        ▼
NAS B Hyper Backup
```

------

# 14. 当前方案能够解决什么

### 可以解决

```text
NAS A 硬件故障
硬盘损坏
误删除仓库
错误修改
较晚发现的数据问题
需要恢复历史状态
主 NAS 所在地点发生物理事故
```

### 不能直接解决

```text
NAS A 故障以后立即切换到 NAS B
```

因为 NAS B 保存的是:

```text
Backup Repository
```

而不是可以直接使用的:

```text
ProjectA.git
ProjectB.git
ProjectC.git
```

需要先 Restore.

------

# 15. 后续可能的第二阶段

如果未来出现新的要求:

> NAS A 故障以后, 希望 NAS B 可以迅速继续提供 Git 服务.

那么需要进一步研究:

```text
Snapshot
+
Replication
+
Failover
```

可能形成:

```text
                 ┌── Replica
                 │
                 │   快速接管
NAS A ───────────┤
                 │
                 └── Hyper Backup
                     
                     历史备份
                     最终数据保护
```

两层分别解决:

```text
Replication
    = 尽快恢复工作

Hyper Backup
    = 数据不要丢
```

这部分暂不纳入当前第一阶段方案.

------

# 16. 当前结论

现阶段采用:

```text
开发机
   ↓ Git
NAS A
主 Bare Repository
   ↓ Hyper Backup
NAS B
异地历史备份
```

核心原则:

```text
Local Git
    = 开发

NAS A
    = 主仓库

NAS B
    = Backup
```

不将 NAS B 当作第二个日常 Git Server.

第一阶段优先解决:

> 数据可靠性.

后续再根据实际需求讨论:

1. NAS A / NAS B 的具体型号.
2. 硬盘容量规划.
3. RAID / SHR 配置.
4. 两地网络连接方式.
5. Hyper Backup 的具体配置.
6. 备份版本保留策略.
7. 完整性检查策略.
8. 是否增加 Snapshot Replication.
9. NAS A 故障后的快速接管方案.
10. 实际灾难恢复演练流程.
