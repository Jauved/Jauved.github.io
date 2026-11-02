---
layout: post
title: "Git 修改最近多次 Commit 的作者"
categories: [Git]
tags: Git Commit Author Committer commit-tree update-ref
math: false


---

# Git 修改最近多次 Commit 的作者

适用场景: 最近几次 Commit 的 `Author` / `Committer` 姓名或邮箱填写错误, 提交尚未 Push, 希望修改身份信息而不重新应用代码和资源变更.

## W - What: 直接使用

### A. 修改最近 N 次提交 (示例: 3 次, 推荐)

以下命令适用于 **Git Bash**, 且目标范围内的提交均为普通线性提交. 在仓库根目录执行. 修改主脚本的 `count=3` 即可调整笔数; 前后的 `git log -3` 是本例的查看命令, 使用其他数量时也请相应调整.

**1. 设置正确身份, 确认提交状态.**

其中设置身份如果已经完成, 则直接用后两句代码确认提交状态即可.

```bash
git config user.name "Correct Name" # 设置作者名字
git config user.email "correct@example.com" # 设置作者邮箱

git status -sb
git log -3 --format="%h | Author: %an <%ae> | Committer: %cn <%ce>" # 此行中的"3"即你需要修改的提交的数量.
```

应确认目标提交均尚未 Push, 且工作区和暂存区干净. `git status -sb` 中的 ahead 数量可作为参考, 必要时先更新远端跟踪信息; 不要将已经推送的提交纳入本脚本的修改范围.

**2. 一次性修改最近 N 次提交.**

在 Git Bash 中运行如下命令, 仅需按实际需要修改 `count=3`:  

```bash
(
    # =========================================================
    # Configuration: 这里的"3"即你需要修改的提交的数量.
    # =========================================================
    count=3

    set -eo pipefail

    # Validate count.
    case "$count" in
        ''|*[!0-9]*|0)
            echo "Invalid commit count: $count"
            exit 1
            ;;
    esac

    # Require a clean working tree.
    test -z "$(git status --porcelain)" || {
        echo "Working tree is not clean"
        exit 1
    }

    # Reject merge commits.
    test -z "$(git rev-list --merges "HEAD~${count}..HEAD")" || {
        echo "Merge commits detected"
        exit 1
    }

    old_head=$(git rev-parse HEAD)
    old_tree=$(git rev-parse HEAD^{tree})
    parent=$(git rev-parse "HEAD~${count}")

    name=$(git config user.name)
    email=$(git config user.email)
    test -n "$name" && test -n "$email" || {
        echo "Git identity must not be empty"
        exit 1
    }

    # Rewrite commit metadata without checking out files.
    while read -r old; do
        tree=$(git rev-parse "$old^{tree}")
        author_date=$(git show -s --format=%aI "$old")
        committer_date=$(git show -s --format=%cI "$old")

        parent=$(
            git cat-file commit "$old" | sed '1,/^$/d' |
            GIT_AUTHOR_NAME="$name" \
            GIT_AUTHOR_EMAIL="$email" \
            GIT_AUTHOR_DATE="$author_date" \
            GIT_COMMITTER_NAME="$name" \
            GIT_COMMITTER_EMAIL="$email" \
            GIT_COMMITTER_DATE="$committer_date" \
            git commit-tree "$tree" -p "$parent"
        )
    done < <(git rev-list --reverse "HEAD~${count}..HEAD")

    # Update branch only after all new commits are created.
    git update-ref HEAD "$parent" "$old_head"

    # Verify the final file tree is unchanged (after updating HEAD).
    test "$(git rev-parse HEAD^{tree})" = "$old_tree"
)
```

**3. 验证并推送.**

```bash
# 检查修改后的信息
git log -3 --format="%h | Author: %an <%ae> | Committer: %cn <%ce>"
git status

# 如果没有问题就执行推送
git push
```

`git status` 应显示工作区干净. 脚本末尾的 Tree 检查发生在更新 HEAD 之后, 若检查失败只会报错退出, 不会自动回滚; 可参照备份章节恢复. 目前这份脚本仍不执行 Rebase、Checkout 或 Git LFS 迁移.

### B. 可选: 在修改前手动创建备份

这一步**不是上述成功版的必需步骤**, 仅供下次操作时使用. 如果需要, 应在运行主脚本**之前**执行:

```bash
git branch backup-before-author-fix-$(date +%Y%m%d%H%M%S)
```

此命令成功时通常没有输出, 请通过下面的命令查看实际创建的分支名:

```bash
git branch --list "backup-before-author-fix-*"
```

只有确实创建了备份分支, 才能通过其实际名称比较修改前后的文件内容. 例如, 若分支名是 `backup-before-author-fix-20261012103000`:

```bash
git diff backup-before-author-fix-20261012103000 HEAD
```

没有输出意味着两个提交所指向的**最终文件快照**一致. 不要将 `BACKUP_BRANCH` 之类的占位符原样执行. 未创建备份分支时, 跳过这项可选验证即可.

### C. 仅修改最近 1 次提交 (更简单)

```bash
git config user.name "Correct Name"
git config user.email "correct@example.com"
git commit --amend --no-edit --reset-author
```

此方案同样不使用 Rebase, 但只适合修改最新一次 Commit; 执行前应确保暂存区没有其他变更.

## I - Insight: 为什么不使用 Rebase

`git rebase` 会重新应用提交, 可能触发历史版本的 `.gitattributes`、Git LFS 过滤器或合并冲突. 对于只想改作者身份的场景, 这些文件处理通常没有必要.

`git commit-tree` 则直接复用每次提交的 **Tree 对象**, 新建带有正确身份和新父提交引用的 Commit 对象. `git update-ref` 在全部新提交生成后, 将当前分支指向新的提交链; 本例随后检查最终 Tree 是否一致. 整个操作不需要检出文件或重新应用 Patch.

| 项目                        | Rebase 修改身份 | `commit-tree` 方案 |
| --------------------------- | --------------- | ------------------ |
| 重新应用提交                | 是              | 否                 |
| 重新检出工作区文件          | 可能            | 否                 |
| 保留各次提交的文件 Tree     | 不保证          | 是, 直接复用       |
| 触发 Git LFS / 属性处理问题 | 可能            | 避免重新检出/过滤  |
| 提交 Hash 改变              | 是              | 是                 |

## S - System: 机制与边界

### 修改了什么, 保留了什么

- 修改: 最近 N 次提交的 `Author` 和 `Committer` 姓名、邮箱, 以及其 Commit Hash.
- 保留: 各次提交引用的 Tree、提交说明文本, 以及原有 `AuthorDate`、`CommitDate`. 其中 `git cat-file commit | sed` 读取原 Commit 消息正文, 避免 `git show -s --format=%B` 额外附加一个换行符.
- 重建: 每次新提交的父提交引用, 使它们连接为新的提交链.
- 不执行: `git checkout`、`git rebase`、Git LFS 历史迁移、换行符归一化.

### 使用限制

- 上述脚本适用于 Git Bash, 不是 PowerShell 原生命令脚本.
- 只处理当前分支最后 N 次普通线性提交, 不支持范围内有 Merge Commit.
- 要求工作区与暂存区干净. 目标提交应当尚未推送, 否则历史改写会影响协作.
- 如果旧提交带有 GPG 签名, 新提交不会自动保留原签名; 特殊 Commit Header 也不保证保留.
- 如果最近 N 次提交中存在 Tag、其他分支引用或关联审核记录, 原引用不会自动改指向新提交.

### 如果备份了分支且需要恢复修改前的提交

如果在修改前实际创建了 `backup-before-author-fix-*` 备份分支, 且**尚未 Push、没有产生新的提交、工作区仍干净, 并确认当前 HEAD 与备份的最终 Tree 一致**, 可以在核对分支名后恢复原分支引用:

```bash
# Find the backup branch created before the rewrite.
git branch --list "backup-before-author-fix-*"

# Replace this example with the actual branch name.
backup="backup-before-author-fix-20261012103000"

# Check and restore as one operation. Stop on any failure.
(
    set -e
    test "$(git rev-parse "$backup^{tree}")" = "$(git rev-parse HEAD^{tree})" || {
        echo "File trees differ; stop and investigate"
        exit 1
    }
    git update-ref HEAD "$(git rev-parse "$backup")" "$(git rev-parse HEAD)"
)
```

`git update-ref` 只恢复当前分支引用, 不主动检出文件. 请不要把示例分支名原样使用, 也不要在已经推送或后续新增提交之后照搬这一恢复命令.

### 实际案例: Unity / Git LFS 的 TGA 文件

修改最近 4 次提交作者时, Rebase 过程中曾出现 `.tga` 文件无法正常 Restore、工作区反复显示 Modified 的现象. 中止 Rebase 后异常消失. 随后使用 `commit-tree` 方案完成作者修改, 工作区保持 Clean, 最终正常 Push.

该案例说明绕过 Rebase 可以避开文件重放阶段的问题, **但不能单凭这一现象断定根因一定是 Git LFS 或 `.gitattributes`**.

## E - Evidence: 官方资料

- [Git - git-commit-tree](https://git-scm.com/docs/git-commit-tree): 基于已有 Tree 创建 Commit, 设置父提交及 Author / Committer 信息.
- [Git - git-update-ref](https://git-scm.com/docs/git-update-ref): 检查旧引用后安全更新分支指针.
- [Git - git-rebase](https://git-scm.com/docs/git-rebase): Rebase 重新应用提交的机制.
- [Git - gitrevisions](https://git-scm.com/docs/gitrevisions): `HEAD~4` 等版本范围语法.
