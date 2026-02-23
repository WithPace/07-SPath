-- 补丁：reports 表缺少 file_url, period, created_by 字段
ALTER TABLE reports ADD COLUMN IF NOT EXISTS file_url VARCHAR(500);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS period VARCHAR(10);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
