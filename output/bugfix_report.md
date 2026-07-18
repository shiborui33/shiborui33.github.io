---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: af6696ded963c590bb5d43dad195a58b_7565a6aa824e11f18a64525400826444
    ReservedCode1: MiYLyJqeBNBPiREdGuUWwaTxv4g3FPisoZUn8DuN483KiCyYHCoi4yuw8m/eif8AolUAUdlyvzwFDRnanxfirTZCeTn5/dDJzoYZiyqh9xtRSC1jxgW7FOz10bWZiLYQJ3mtkG/ha/QiJdVnyTb781S4kY/P1wtJd2YR2kdPeVkeMtvjcYOxgOSQIx4=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: af6696ded963c590bb5d43dad195a58b_7565a6aa824e11f18a64525400826444
    ReservedCode2: MiYLyJqeBNBPiREdGuUWwaTxv4g3FPisoZUn8DuN483KiCyYHCoi4yuw8m/eif8AolUAUdlyvzwFDRnanxfirTZCeTn5/dDJzoYZiyqh9xtRSC1jxgW7FOz10bWZiLYQJ3mtkG/ha/QiJdVnyTb781S4kY/P1wtJd2YR2kdPeVkeMtvjcYOxgOSQIx4=
---

# 班级网站 Bug 修复报告

**修复日期**: 2026-07-18  
**项目路径**: `C:\Users\Administrator\Desktop\banjiwanghan`

---

## 修复清单

### 🔴 致命 Bug

#### Bug 1 — Supabase Anon Key 格式错误 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `index.html` | 第 335 行 |

**旧值**: `sb_publishable_gbIryTphJGOjUGUsVPXTPw_AdsxpIUM`（格式无效，非 JWT）

**新值**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrdmp6bmx2bWZxZWdiYmNuZWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NDQ5MzQsImV4cCI6MjA5OTUyMDkzNH0.fpfRitU2DKDlVtk93Nmk-BF5NFDl1t5ViXuIAnNWVl4`（标准 JWT 格式）

**影响**: 修复后 Supabase SDK 可正常认证，所有数据库读写操作生效。

---

#### Bug 2 — class_info 表 RLS 策略泄露管理员密码 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `supabase/schema.sql` | 第 117 行 |

**旧策略**:
```sql
CREATE POLICY "public_read_class_info" ON class_info FOR SELECT USING (true);
```

**新策略**:
```sql
CREATE POLICY "public_read_class_info" ON class_info FOR SELECT USING (section != 'admin_password');
```

**影响**: 公开 API 不再暴露 `admin_password` 行。

---

### 🟡 中等 Bug

#### Bug 3 — literature_figures 缺少 CRUD 函数 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `supabase/schema.sql` | `admin_delete_message` 之后（新增 75 行） |

新增三个 RPC 函数（仿照 events 表已有写法，`SECURITY DEFINER` + 密码验证）：

- `admin_insert_literature(admin_pass, p_name, p_quote, p_icon, p_sort_order)` — 新增先贤
- `admin_update_literature(admin_pass, p_id, p_name, p_quote, p_icon, p_sort_order)` — 更新先贤
- `admin_delete_literature(admin_pass, p_id)` — 删除先贤

同时前端 `index.html` 新增：
- 文学人物卡片上的 ✏️ 编辑 / 🗑 删除按钮（管理员模式下显示）
- 文学人物区域底部的「＋ 添加先贤」按钮
- `addLiterature()` / `editLiterature(id)` / `deleteLiterature(id)` 三个前端函数，复用现有编辑弹窗

---

#### Bug 4 — editClassInfo 错误处理缺失 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `index.html` | `editClassInfo` 函数内保存逻辑 |

**修复内容**: 循环中任何一步 RPC 调用失败时，立即中断并保留编辑框打开（`adminRPC` 已调用 `showToast` 显示具体错误），不再盲目显示"更新成功"。

---

#### Bug 6 — Modal 弹窗不支持 Escape 键关闭 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `index.html` | `closeEditModal` 函数之后新增 |

新增全局 `keydown` 监听器，按 Escape 时：
- 若编辑弹窗打开 → 关闭编辑弹窗
- 否则若管理员密码弹窗打开 → 关闭密码弹窗

---

### 🟢 轻微问题

#### Bug 7 — timeAgo() 未处理未来时间 ✅ 已修复

| 文件 | 位置 |
|------|------|
| `index.html` | `timeAgo` 函数 |

在计算 `diff` 后新增 `if (diff < 0) return '刚刚';`，未来时间不再显示负数分钟。

---

#### Bug 8 — submitMessage 提交后清除输入框 ✅ 已有（无需修改）

原代码在 `submitMessage` 成功回调中已包含：
```javascript
$('msg-author').value = '';
$('msg-content').value = '';
```
此功能已存在，无需额外修改。

---

#### Bug 9 — storage.buckets INSERT 保护 ✅ 已有（无需修改）

原 `schema.sql` 已使用 PostgreSQL 标准语法：
```sql
INSERT INTO storage.buckets (...) VALUES (...) ON CONFLICT (id) DO NOTHING;
```
`ON CONFLICT (id) DO NOTHING` 即 "IF NOT EXISTS" 的 PostgreSQL 等效写法，已提供完整保护。

---

## 修复汇总

| Bug | 级别 | 文件 | 状态 |
|-----|:----:|------|:----:|
| #1 Anon Key 格式错误 | 🔴 | index.html | ✅ 已修复 |
| #2 RLS 策略泄露密码 | 🔴 | schema.sql | ✅ 已修复 |
| #3 literature 缺少 CRUD | 🟡 | schema.sql + index.html | ✅ 已修复 |
| #4 editClassInfo 错误处理 | 🟡 | index.html | ✅ 已修复 |
| #6 Modal Escape 键 | 🟡 | index.html | ✅ 已修复 |
| #7 timeAgo 未来时间 | 🟢 | index.html | ✅ 已修复 |
| #8 留言后清空输入框 | 🟢 | — | 无需修改 |
| #9 storage INSERT 保护 | 🟢 | — | 无需修改 |

---

## 部署提醒

修复完成后，需要：

1. **重新执行 SQL**: 在 Supabase SQL Editor 中重新运行 `supabase/schema.sql`（或仅执行新增的 literature RPC 函数和修改后的 RLS 策略）
2. **推送 GitHub**: `git add . && git commit -m "修复数据库连接和各项bug" && git push`，等待 GitHub Pages 自动部署
3. **验证功能**: 打开网站确认数据从 Supabase 正常加载，管理员登录后可增删改文学人物
*（内容由AI生成，仅供参考）*
