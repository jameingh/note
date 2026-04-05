# bb-browser 保存 X 文章的最佳实践

## 完整工作流程

### 步骤 1：确认浏览器状态

```bash
# 检查 Chrome 是否运行
pgrep -x "Google Chrome" >/dev/null && echo "Chrome 正在运行" || echo "Chrome 未运行"

# 检查 CDP 端口是否可用
curl -s http://localhost:9222/json/version 2>&1 | head -5
```

**如果 Chrome 未运行**，需要先启动 Chrome（端口 9222 需已开启）。

### 步骤 2：打开目标文章

```bash
bb-browser --port 9222 open "<文章 URL>"
```

等待 3-5 秒让页面加载：
```bash
sleep 5
```

### 步骤 3：确认页面加载完成

```bash
# 获取页面快照确认内容已加载
bb-browser --port 9222 snapshot -d 8

# 或者获取标题确认
bb-browser --port 9222 get title
```

如果页面显示"Something went wrong"或加载中，刷新页面：
```bash
bb-browser --port 9222 refresh && sleep 5
```

### 步骤 4：滚动页面加载完整内容

X 文章可能需要滚动才能加载完整内容：

```bash
# 向下滚动加载更多内容
bb-browser --port 9222 scroll down 500
sleep 2
bb-browser --port 9222 scroll down 1000
sleep 3
```

### 步骤 5：提取文章完整内容

```bash
# 获取完整页面文本
bb-browser --port 9222 eval 'document.documentElement.innerText'
```

### 步骤 6：提取文章图片链接

```bash
# 获取文章内的图片（过滤掉头像等无关图片）
bb-browser --port 9222 eval 'Array.from(document.querySelectorAll("article img")).filter(img => img.src.includes("pbs.twimg.com/media")).map(img => img.src).join("\n")'
```

### 步骤 7：获取当前 URL 确认

```bash
bb-browser --port 9222 get url
```

### 步骤 8：关闭标签页

```bash
bb-browser --port 9222 close
```

## Markdown 格式要点

### 文章元数据
- 标题：使用 `# `
- 作者：`**作者：** 名称 (@username)`
- 发布日期：`**发布日期：** YYYY 年 MM 月 DD 日`
- 原文链接：`**原文链接：** URL`

### 图片格式
```markdown
![描述](图片 URL)
```

封面图片放在标题后，正文中的图片放在对应位置。

### 内容结构
- 大标题：`## `
- 小标题：`### `
- 引用：`> 引用内容`
- 代码块：\`\`\` 代码 \`\`\`
- 分隔线：`---`
- 粗体：`**文字**`

## 常见问题与解决方案

### 问题 1：bb-browser 提示 "Could not start browser"
**原因**：Chrome 未运行或 CDP 端口未开启

**解决方案**：
1. 确认 Chrome 已启动并开启远程调试端口
2. 使用 `--port 9222` 参数连接现有 Chrome

### 问题 2：打开错误的文章
**原因**：X 文章引用了其他文章，容易混淆

**解决方案**：
1. 打开 URL 后立即用 `get url` 确认
2. 用 `snapshot` 或 `eval` 提取标题确认内容
3. 如发现错误，`close` 后重新 `open` 正确的 URL

### 问题 3：文章内容不完整
**原因**：X 文章需要滚动才能加载完整内容

**解决方案**：
1. 打开页面后等待至少 5 秒
2. 滚动页面：`scroll down 500` → 等待 → `scroll down 1000`
3. 重新获取内容

### 问题 4：图片链接包含无关头像
**原因**：`document.querySelectorAll("img")` 会获取所有图片

**解决方案**：
过滤时限定为文章内媒体图片：
```javascript
// 只获取媒体图片，排除头像
.filter(img => img.src.includes("pbs.twimg.com/media"))
```

### 问题 5：Markdown 排版混乱
**原因**：直接复制页面文本会包含大量 UI 元素

**解决方案**：
1. 用 `eval` 定位 `article` 元素提取正文
2. 手动整理 Markdown 结构（标题层级、分隔线）
3. 保留原文的关键格式（引用、代码块、粗体）

## 完整示例命令序列

```bash
# 1. 确认 Chrome 运行
pgrep -x "Google Chrome"

# 2. 打开文章
bb-browser --port 9222 open "https://x.com/username/article/ID"

# 3. 等待加载
sleep 5

# 4. 确认页面
bb-browser --port 9222 get title

# 5. 滚动加载完整内容
bb-browser --port 9222 scroll down 500 && sleep 2
bb-browser --port 9222 scroll down 1000 && sleep 3

# 6. 提取内容
bb-browser --port 9222 eval 'document.documentElement.innerText'

# 7. 提取图片
bb-browser --port 9222 eval 'Array.from(document.querySelectorAll("article img")).filter(img => img.src.includes("pbs.twimg.com/media")).map(img => img.src).join("\n")'

# 8. 关闭标签页
bb-browser --port 9222 close
```

## 经验教训

| 问题 | 教训 | 下次改进 |
|------|------|----------|
| Chrome 未启动 | 必须先确认浏览器状态 | 第一步检查 Chrome |
| 打开错误文章 | X 文章会引用其他文章 | 打开后立即确认 URL 和标题 |
| 内容不完整 | X 需要滚动加载 | 必须滚动 + 等待 |
| 图片太多 | 包含头像等无关图片 | 过滤 `pbs.twimg.com/media` |
| 排版混乱 | 直接复制包含 UI 元素 | 手动整理 Markdown 结构 |

---

*本文档基于 2026-03-27 使用 bb-browser 保存 X 文章的实际经验总结*
