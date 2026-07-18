-- =============================================
-- 高一九班 班级网站 - Supabase 数据库 Schema
-- 在 Supabase SQL Editor 中执行此文件
-- =============================================

-- 1. 班级信息表（愿景、班主任寄语、口号等可编辑文本）
CREATE TABLE class_info (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  section     TEXT UNIQUE NOT NULL,
  content     TEXT NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE class_info IS '班级核心信息（愿景、寄语、口号）';
COMMENT ON COLUMN class_info.section IS '标识: vision / teacher_message / slogan / admin_password';

-- 2. 班级事件表（时间线）
CREATE TABLE events (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title       TEXT NOT NULL,
  date_text   TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url   TEXT,
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE events IS '班级纪年 - 时间线事件';

-- 3. 同学风采表
CREATE TABLE members (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url   TEXT,
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE members IS '同窗风采 - 班委/同学介绍';

-- 4. 班级掠影表
CREATE TABLE gallery_photos (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url   TEXT NOT NULL,
  section     TEXT DEFAULT 'gallery',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE gallery_photos IS '班级掠影 - 活动照片墙';

-- 5. 留言板表
CREATE TABLE messages (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author      TEXT NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE messages IS '留言板 - 同学互动留言';

-- 6. 文学人物表
CREATE TABLE literature_figures (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL,
  quote       TEXT NOT NULL,
  icon        TEXT DEFAULT '📖',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE literature_figures IS '文海泛舟 - 先贤人物卡片';

-- =============================================
-- RLS (Row Level Security) 策略
-- =============================================

-- 启用所有表的 RLS
ALTER TABLE class_info       ENABLE ROW LEVEL SECURITY;
ALTER TABLE events           ENABLE ROW LEVEL SECURITY;
ALTER TABLE members          ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_photos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages         ENABLE ROW LEVEL SECURITY;
ALTER TABLE literature_figures ENABLE ROW LEVEL SECURITY;

-- 公开读取策略：所有表允许任何人读取
CREATE POLICY "public_read_class_info"   ON class_info          FOR SELECT USING (section != 'admin_password');
CREATE POLICY "public_read_events"       ON events              FOR SELECT USING (true);
CREATE POLICY "public_read_members"      ON members             FOR SELECT USING (true);
CREATE POLICY "public_read_gallery"      ON gallery_photos      FOR SELECT USING (true);
CREATE POLICY "public_read_messages"     ON messages            FOR SELECT USING (true);
CREATE POLICY "public_read_literature"   ON literature_figures  FOR SELECT USING (true);

-- 公开写入策略：留言板允许任何人插入
CREATE POLICY "public_insert_messages"   ON messages       FOR INSERT WITH CHECK (true);

-- =============================================
-- 管理员验证函数
-- =============================================

CREATE OR REPLACE FUNCTION verify_admin(pass TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  stored_password TEXT;
BEGIN
  SELECT content INTO stored_password
  FROM class_info
  WHERE section = 'admin_password';

  RETURN stored_password IS NOT NULL AND stored_password = pass;
END;
$$;

-- =============================================
-- 管理操作 RPC 函数 (SECURITY DEFINER)
-- =============================================

-- 班级信息更新
CREATE OR REPLACE FUNCTION admin_update_class_info(
  admin_pass TEXT,
  p_section  TEXT,
  p_content  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  INSERT INTO class_info (section, content, updated_at)
  VALUES (p_section, p_content, NOW())
  ON CONFLICT (section)
  DO UPDATE SET content = p_content, updated_at = NOW();

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 事件新增
CREATE OR REPLACE FUNCTION admin_insert_event(
  admin_pass  TEXT,
  p_title     TEXT,
  p_date_text TEXT,
  p_description TEXT,
  p_image_url TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  INSERT INTO events (title, date_text, description, image_url, sort_order)
  VALUES (p_title, p_date_text, p_description, p_image_url, p_sort_order);

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 事件更新
CREATE OR REPLACE FUNCTION admin_update_event(
  admin_pass    TEXT,
  p_id          UUID,
  p_title       TEXT,
  p_date_text   TEXT,
  p_description TEXT,
  p_image_url   TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  UPDATE events SET
    title       = COALESCE(p_title, title),
    date_text   = COALESCE(p_date_text, date_text),
    description = COALESCE(p_description, description),
    image_url   = COALESCE(p_image_url, image_url),
    sort_order  = COALESCE(p_sort_order, sort_order),
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 事件删除
CREATE OR REPLACE FUNCTION admin_delete_event(
  admin_pass TEXT,
  p_id       UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  DELETE FROM events WHERE id = p_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- 同学新增
CREATE OR REPLACE FUNCTION admin_insert_member(
  admin_pass   TEXT,
  p_name       TEXT,
  p_title      TEXT,
  p_description TEXT,
  p_image_url  TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  INSERT INTO members (name, title, description, image_url, sort_order)
  VALUES (p_name, p_title, p_description, p_image_url, p_sort_order);

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 同学更新
CREATE OR REPLACE FUNCTION admin_update_member(
  admin_pass    TEXT,
  p_id          UUID,
  p_name        TEXT DEFAULT NULL,
  p_title       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_image_url   TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  UPDATE members SET
    name        = COALESCE(p_name, name),
    title       = COALESCE(p_title, title),
    description = COALESCE(p_description, description),
    image_url   = COALESCE(p_image_url, image_url),
    sort_order  = COALESCE(p_sort_order, sort_order),
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 同学删除
CREATE OR REPLACE FUNCTION admin_delete_member(
  admin_pass TEXT,
  p_id       UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  DELETE FROM members WHERE id = p_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- 照片新增
CREATE OR REPLACE FUNCTION admin_insert_gallery(
  admin_pass   TEXT,
  p_title      TEXT,
  p_description TEXT,
  p_image_url  TEXT,
  p_section    TEXT DEFAULT 'gallery',
  p_sort_order INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  INSERT INTO gallery_photos (title, description, image_url, section, sort_order)
  VALUES (p_title, p_description, p_image_url, p_section, p_sort_order);

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 照片更新
CREATE OR REPLACE FUNCTION admin_update_gallery(
  admin_pass    TEXT,
  p_id          UUID,
  p_title       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_image_url   TEXT DEFAULT NULL,
  p_section     TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  UPDATE gallery_photos SET
    title       = COALESCE(p_title, title),
    description = COALESCE(p_description, description),
    image_url   = COALESCE(p_image_url, image_url),
    section     = COALESCE(p_section, section),
    sort_order  = COALESCE(p_sort_order, sort_order),
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 照片删除
CREATE OR REPLACE FUNCTION admin_delete_gallery(
  admin_pass TEXT,
  p_id       UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  DELETE FROM gallery_photos WHERE id = p_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- 留言删除（管理员）
CREATE OR REPLACE FUNCTION admin_delete_message(
  admin_pass TEXT,
  p_id       UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  DELETE FROM messages WHERE id = p_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- 文学人物新增
CREATE OR REPLACE FUNCTION admin_insert_literature(
  admin_pass  TEXT,
  p_name      TEXT,
  p_quote     TEXT,
  p_icon      TEXT DEFAULT '📖',
  p_sort_order INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  INSERT INTO literature_figures (name, quote, icon, sort_order)
  VALUES (p_name, p_quote, p_icon, p_sort_order);

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 文学人物更新
CREATE OR REPLACE FUNCTION admin_update_literature(
  admin_pass   TEXT,
  p_id         UUID,
  p_name       TEXT DEFAULT NULL,
  p_quote      TEXT DEFAULT NULL,
  p_icon       TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  UPDATE literature_figures SET
    name       = COALESCE(p_name, name),
    quote      = COALESCE(p_quote, quote),
    icon       = COALESCE(p_icon, icon),
    sort_order = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 文学人物删除
CREATE OR REPLACE FUNCTION admin_delete_literature(
  admin_pass TEXT,
  p_id       UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  DELETE FROM literature_figures WHERE id = p_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- =============================================
-- Storage Bucket 设置
-- =============================================

-- 创建公开的照片存储桶
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'class-photos',
  'class-photos',
  true,
  10485760,  -- 10MB 上限
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- 存储策略：公开可读
CREATE POLICY "public_read_photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'class-photos');

-- 存储策略：通过 RPC 上传（管理员验证放在函数里）
CREATE POLICY "rpc_insert_photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'class-photos');

-- =============================================
-- 照片上传 RPC 函数（管理员专用）
-- =============================================

CREATE OR REPLACE FUNCTION admin_upload_photo(
  admin_pass TEXT,
  p_filename TEXT,
  p_base64  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_url TEXT;
BEGIN
  IF NOT verify_admin(admin_pass) THEN
    RETURN jsonb_build_object('success', false, 'error', '密码错误');
  END IF;

  -- 照片上传由前端 JS 通过 Supabase SDK 直接处理
  -- 此函数仅作权限验证入口，实际上传走 storage API
  RETURN jsonb_build_object('success', true, 'path', 'class-photos/' || p_filename);
END;
$$;
