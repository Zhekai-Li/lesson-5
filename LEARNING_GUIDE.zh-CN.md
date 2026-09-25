# Intersections Library 中文学习指南

这份指南帮助你按作业要求理解整个仓库。目标不是背代码，而是能够回答三个问题：每个文件负责什么、它接收和输出什么、它如何与下一层连接。

## 1. 先建立整体模型

项目遵循老师规定的分层结构：

```text
用户输入
  ↓
app.sh
  ↓
ui/                    负责交互和展示
  ↓
workflows/             负责组织步骤
  ↓
books/ recommendations/ 负责单一业务能力
  ↓
data/book_database.sh  唯一数据入口
  ↓
data/books.csv         持久化存储
```

最重要的设计原则是：上层不越过下层。UI 不直接读取 CSV，推荐程序也不直接读取 CSV；它们都调用 `data/book_database.sh`。

## 2. 推荐的阅读顺序

按下面顺序阅读，每次只回答“输入、处理、输出”三个问题。

1. [`app.sh`](app.sh)：程序入口，检查 Gum，然后启动 UI。
2. [`ui/main_menu.sh`](ui/main_menu.sh)：观察用户可以选择哪些操作。
3. [`workflows/manage_library.sh`](workflows/manage_library.sh)：理解普通图书操作如何被协调。
4. [`data/book_database.sh`](data/book_database.sh)：理解 CSV 的唯一读写边界。
5. [`books/fetch_book_metadata.sh`](books/fetch_book_metadata.sh) 和 [`books/search_books.sh`](books/search_books.sh)：理解小组件如何保持单一职责。
6. [`workflows/get_recommendations.sh`](workflows/get_recommendations.sh)：寻找 `&`、`$!`、`wait` 和 `|`。
7. `recommendations/` 下的四个文件：比较三种独立策略以及最后的 refinement。
8. [`tests/test.sh`](tests/test.sh)：用测试反向确认每个接口的契约。

## 3. 文件职责速查

| 文件 | 输入 | 输出/作用 |
|---|---|---|
| `app.sh` | 无参数或 `--demo` | 启动交互 UI 或隔离演示 |
| `ui/main_menu.sh` | Gum 选择和文本输入 | 调用 workflow，不保存业务逻辑 |
| `ui/library_screen.sh` | stdin 中的七列 TSV | 用 Gum 显示图书表格 |
| `ui/recommendations_screen.sh` | stdin 中的七列推荐 TSV | 用 Gum 显示最终推荐 |
| `workflows/manage_library.sh` | `list/add/search/update-*` | 组合 metadata、search 和 database |
| `workflows/get_recommendations.sh` | 兴趣关键词 | 并行运行三个 agent，合并并 refine |
| `books/fetch_book_metadata.sh` | title + author | 五列 TSV：title、author、genre、year、link |
| `books/search_books.sh` | 参数或 stdin 中的关键词 | 匹配的七列图书 TSV |
| `recommend_from_history.sh` | 当前书库 | 与高评分/已读类型相近的候选 |
| `recommend_from_interests.sh` | 兴趣关键词 | 标签匹配的候选 |
| `recommend_for_discovery.sh` | 当前书库 | 书库尚未覆盖类型的候选 |
| `refine_recommendations.sh` | stdin 中的候选集合 | 去重、排除已有图书、排序后的最多五项 |
| `data/book_database.sh` | 数据命令和参数 | 查询 TSV 或原子更新 CSV |
| `data/books.csv` | — | 持久化书库 |

## 4. 两种数据格式

磁盘使用 CSV，组件之间使用 TSV。

CSV schema：

```text
title,author,genre,year,status,rating,link
```

CSV 适合持久化，但字段可能包含逗号和双引号，所以 `book_database.sh` 负责引用、解析和转义。其他组件收到的是无表头 TSV：

```text
title<TAB>author<TAB>genre<TAB>year<TAB>status<TAB>rating<TAB>link
```

推荐候选也是七列 TSV，但字段不同：

```text
score<TAB>title<TAB>author<TAB>genre<TAB>year<TAB>reason<TAB>link
```

记住一句话：CSV 是存储契约，TSV 是程序之间的通信契约。

## 5. 完整流程一：添加图书

以在菜单中添加 *The Gene* 为例：

```text
main_menu.sh
  │ 收集 title、author、status、rating
  ▼
manage_library.sh add
  │ 调用离线 metadata catalog
  ▼
fetch_book_metadata.sh
  │ 返回 genre、year、link
  ▼
book_database.sh add
  │ 校验、查重、CSV 转义、临时文件 + mv
  ▼
books.csv
```

对应命令：

```bash
./workflows/manage_library.sh add \
  "The Gene" "Siddhartha Mukherjee" want-to-read ""
```

这里的关键点：workflow 只协调，metadata 只补充信息，database 只处理存储。

## 6. 完整流程二：搜索

菜单中的搜索经过以下路径：

```text
main_menu.sh
  → manage_library.sh search
  → search_books.sh
  → book_database.sh search
  → library_screen.sh
```

`search_books.sh` 同时支持参数和管道输入：

```bash
./books/search_books.sh history
printf 'history\n' | ./books/search_books.sh
```

这是“小程序 + 简单接口”的示例：搜索组件不显示 UI，也不解析 CSV。

## 7. 完整流程三：并行推荐

这是作业最重要的 workflow：

```text
                           ┌─ history agent ────┐
兴趣 + 当前书库 ────────────┼─ interests agent ─┼─→ cat → refine → Gum table
                           └─ discovery agent ─┘
```

在 `get_recommendations.sh` 中寻找四组证据：

1. `&`：把三个 agent 放到后台并发执行。
2. `$!`：保存每个后台进程的 PID。
3. `wait "$pid"`：同步，确保结果完成后再合并。
4. `cat ... | refine_recommendations.sh`：通过 pipe 把候选传给 refinement。

进度信息写入 stderr：

```bash
printf '[recommendations] ...\n' >&2
```

最终 TSV 写入 stdout。这样状态信息不会污染管道中的结构化数据。

三个 agent 的区别：

- History：统计已完成图书的 genre，并让评分成为权重。
- Interests：把用户关键词与离线 catalog 的 title、genre、tags 匹配。
- Discovery：寻找当前书库没有覆盖的 genre，鼓励探索。

Refinement 做四件事：排除已有图书、按 title + author 去重、保留最高分版本、排序后限制为五项。

## 8. Bash 技术点与作业要求的对应关系

| 作业概念 | 在哪里看 | 应该会解释什么 |
|---|---|---|
| Small Bash programs | 所有 `.sh` 文件 | 每个文件只有一个主要职责 |
| Modular architecture | 目录结构 | UI、workflow、component、data 分层 |
| Pipes | `get_recommendations.sh` | stdout 数据如何进入 refinement |
| Parallelization | `get_recommendations.sh` | `&`、`$!`、`wait` 的关系 |
| Streaming/progress | 推荐 workflow 的 stderr | 用户为何能看到 running/done 信息 |
| Gum | `ui/*.sh` | 菜单、输入和表格如何呈现 |
| Persistence | `book_database.sh` | CSV 如何安全读取和原子更新 |
| Personalization | catalog、starter shelf、三种 agent | 跨科技、历史、心理学与文学的阅读偏好 |

## 9. 为什么数据库更新是“原子的”

添加或更新不会直接在原文件中间修改内容，而是：

1. 创建同目录临时文件。
2. 把完整新内容写入临时文件。
3. 成功后用 `mv` 替换原文件。

如果写入失败，旧数据库仍然存在。测试通过比较更新前后的 inode，验证文件确实被替换。

## 10. 安全练习命令

先运行测试，它使用临时数据库，不修改真实书库：

```bash
./tests/test.sh
```

然后运行隔离演示：

```bash
./app.sh --demo
```

单独观察推荐的 stdout 和 stderr：

```bash
./workflows/get_recommendations.sh \
  "technology history psychology literature" \
  > /tmp/recommendations.tsv \
  2> /tmp/recommendations-progress.log

cat /tmp/recommendations-progress.log
cat /tmp/recommendations.tsv
```

最后启动交互应用：

```bash
./app.sh
```

建议亲自完成 Browse、Search 和 Recommendations，再尝试 Add、Update Status、Update Rating。

## 11. 口头讲解练习

**为什么只有一个文件可以接触 `books.csv`？**

为了建立数据抽象边界。以后把 CSV 换成 SQLite 时，上层接口可以保持不变。

**为什么推荐 agent 可以并行？**

三种策略互不依赖，只需要读取同一份书库和 catalog，所以可以同时运行；workflow 最后用 `wait` 同步。

**为什么进度写 stderr？**

stdout 必须保持为干净的 TSV，才能继续通过 pipe 交给下一个程序；stderr 专门用于面向用户的状态。

**为什么需要 refinement？**

三个 agent 可能推荐同一本书。Refinement 统一排除已有书、去重、保留最高分并限制结果数量。

**这个项目个性化在哪里？**

初始书架和 catalog 跨越技术、历史、心理学、科幻与文学；三个 agent 分别平衡熟悉领域、当前兴趣和探索性。

**Codex 是否是运行依赖？**

不是。应用运行时只需要 Bash、Gum 和仓库内的离线数据。

## 12. 最终自检

你应当能够不看答案完成下面的解释：

1. 从 `app.sh` 开始说出五层架构。
2. 说出两种七列 TSV 的字段顺序。
3. 指出推荐 workflow 中的 `&`、`$!`、`wait` 和 `|`。
4. 追踪一次 Add Book 或 Recommendations 的完整路径。
5. 解释为什么 stderr 和 stdout 必须分开。
6. 解释临时文件加 `mv` 如何保护 CSV。

能完成这六项，就已经达到作业要求的“理解端到端架构”。
