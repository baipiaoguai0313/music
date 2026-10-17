-- =========================================================
-- 次元星域音乐 · 账号 / 收藏 / 歌单（Cloudflare D1）
-- 手动初始化（可选；Worker 首次启动也会自动建表）：
--   npx wrangler d1 execute music-db --remote --file=./schema.sql
-- =========================================================

CREATE TABLE IF NOT EXISTS users (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  username    TEXT UNIQUE NOT NULL,
  pass_salt   TEXT NOT NULL,
  pass_hash   TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  token       TEXT PRIMARY KEY,
  user_id     INTEGER NOT NULL,
  created_at  INTEGER NOT NULL,
  expires_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS playlists (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER NOT NULL,
  name        TEXT NOT NULL,
  is_default  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS playlist_songs (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  playlist_id  INTEGER NOT NULL,
  server       TEXT NOT NULL,
  song_id      TEXT NOT NULL,
  title        TEXT,
  artist       TEXT,
  pic          TEXT,
  added_at     INTEGER NOT NULL,
  UNIQUE (playlist_id, server, song_id)
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_user ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_songs_pl      ON playlist_songs(playlist_id);
CREATE INDEX IF NOT EXISTS idx_songs_song    ON playlist_songs(server, song_id);
