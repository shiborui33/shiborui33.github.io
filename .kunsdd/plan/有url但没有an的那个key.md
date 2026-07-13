在 Supabase 项目面板中：

1. 左侧菜单最下面，点击 **齿轮图标 ⚙️ → "Project Settings"**
2. 在设置页面中，点击左侧的 **"API"**（或者 "Data API"）
3. 你会看到两个区块：
   - **Project URL** ← 你找到了
   - **Project API Keys** ← anon key 在这里

在 **Project API Keys** 区域，有 `anon` 和 `service_role` 两行：

```
anon public
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...
```

**复制 `anon public` 下面那一长串**（以 `eyJ` 开头），这个就是 anon key。

---

> ⚠️ 注意：复制的是 **anon public** 那一行，**不是** `service_role secret`（那个是密钥，不能泄露）

如果你看到的界面是英文的，截图给我看，我帮你找。