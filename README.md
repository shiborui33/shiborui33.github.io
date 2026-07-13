# 高一九班 班级网站 — 部署指南

## 📁 项目结构

```
banjiwanghan/
├── index.html          ← 网站主页（包含前台 + 后台管理）
├── supabase/
│   ├── schema.sql      ← 数据库建表 + RLS 策略 + RPC 函数
│   └── seed.sql        ← 种子数据（从静态网站迁移）
├── banji.jpg           ← 首页背景图
├── *.jpg, *.mp4        ← 班级照片和视频资源
└── README.md           ← 本文件
```

## 🚀 快速开始（3 步上线）

### 第一步：创建 Supabase 项目

1. 打开 [supabase.com](https://supabase.com)，注册/登录
2. 点击 **New project**，填写：
   - Name: `gaoyijiuban`（随便填）
   - Database Password: 设置一个强密码（记下来）
   - Region: 选择 **Northeast Asia (Seoul)** 或 **Southeast Asia (Singapore)**
3. 点击 **Create project**，等待 1-2 分钟初始化完成

### 第二步：初始化数据库

1. 进入项目后，左侧菜单点击 **SQL Editor**
2. 点击 **New query**
3. 复制 `supabase/schema.sql` 的全部内容，粘贴到编辑器
4. 点击右下角 **Run**（绿色按钮），等待执行成功
5. 再次 **New query**
6. 复制 `supabase/seed.sql` 的全部内容，粘贴执行
7. 验证：左侧菜单点击 **Table Editor**，应该能看到 6 张表：
   - `class_info`、`events`、`members`、`gallery_photos`、`messages`、`literature_figures`

### 第三步：配置网站并部署

1. 左侧菜单 → **Project Settings** → **API**
2. 复制 **Project URL**（类似 `https://xxxxx.supabase.co`）
3. 复制 **anon public key**（很长一串）
4. 用文本编辑器打开 `index.html`，找到第 **334-335** 行：

```javascript
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...你的anon key';
```

5. 替换为你的真实 URL 和 Key
6. 将整个项目推送到 GitHub Pages（和之前一样的部署方式）

## 🔑 后台管理

### 登录方式
- 网站右下角有一个灰色的 **⚙** 小按钮
- 点击后输入密码: **`gjyb2026`**（种子数据中设置的默认密码）
- ⚠️ **上线后务必修改密码**：在 Supabase → Table Editor → `class_info` 表 → 找到 `admin_password` 行 → 修改 `content` 字段

### 管理功能
登录后可以：
- ✏️ **编辑班级信息**（愿景、寄语、口号）
- ➕ **新增/编辑/删除** 班级事件
- ➕ **新增/编辑/删除** 同学风采
- ➕ **新增/编辑/删除** 照片掠影
- 🗑️ **删除** 不当留言

## 📸 照片管理

### 方式一：使用 Supabase Storage（推荐）

1. 左侧菜单 → **Storage** → **New bucket**
2. Bucket name: `class-photos`，勾选 **Public bucket**
3. 上传照片后，点击照片 → **Get URL** → 复制链接
4. 在网站后台管理中粘贴该 URL

### 方式二：继续使用本地文件

如果照片不多，也可以保留在项目文件夹中，直接输入文件名即可（如 `banji.jpg`）

## 🏷️ 留言板

- 访客可以直接在网站底部留言
- 无需注册/登录，填写名字和内容即可
- 留言按时间倒序显示
- 管理员可以删除不当留言

## 🔒 安全说明

- 数据库 RLS 已启用，公开接口只能读取和留言
- 所有增删改操作必须通过 RPC 函数 + 管理员密码验证
- 密码存储在数据库中，建议定期更换
- 数据库 `anon key` 是公开的（只能读+留言），`service_role key` 不要暴露

## ❓ 常见问题

**Q: 网站打开后显示"数据库未连接"？**
A: 检查 `index.html` 中的 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY` 是否正确

**Q: 种子数据导入失败？**
A: 确保先执行 `schema.sql`，再执行 `seed.sql`

**Q: 照片上传到哪里？**
A: 照片上传到 Supabase Storage，然后在管理员面板中输入返回的 URL

---

> 🏫 汤阴县高级中学 · 高一九班 · 以文载道 以史明志
