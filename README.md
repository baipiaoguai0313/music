# ♪ 次元星域音乐

[在线体验](https://music.107211.xyz)

单文件音乐播放器，可部署于 Cloudflare Worker，默认零成本。搜索、播放开箱即用，无需任何配置。

另外支持**账号密码注册/登录**、**收藏歌曲**与**自建歌单**：数据存在免费的 Cloudflare D1 数据库里，**歌单跟随账号，换设备、换浏览器登录同一账号即可同步**；不绑定 D1 也完全不影响搜索与播放，只是顶栏不出现账号入口。

本站另可选配自制 [Oauth 登录授权平台](https://oauth.107211.xyz/)（第三方 OAuth），用于判断和保护账号读取与授权。

当前仅可播放非 VIP 歌曲，若需更改 Meting API，则将 [worker.js](worker.js)内的所有 `https://api.107211.xyz/api`的域名部分（共6处）修改为你自部署的 API 域名即可，如 `https://api.ciallo.cc/api`，注意使用的 Meting API 功能需与当前 API 功能一致，否则对不上可能影响使用

## 功能

- **搜索与播放**：网易云 / QQ音乐 / 酷狗 / 酷我 / 百度，启动时后台静默检测音乐源，速度仅需10ms
- **三种播放方式**：顺序 / 单曲 / 随机
- **收听记录**：真正出声才记，按 `server:id` 去重，上限 300 条。仅 `OAUTH_ON=true` 时可见
- **歌单导入**：粘贴歌单 ID 或**网易云歌单**链接，点封面整张进队列
- **账号注册 / 登录**：用户名 + 密码，密码 PBKDF2-SHA256 加盐哈希（10 万次迭代），会话 30 天有效。绑定 D1 后可用
- **收藏与云歌单**：每首歌右侧点 ♥ 即可收藏到歌单；注册即建默认「我的收藏」，可自建/删除多个歌单；歌单和收藏全部跟随账号存云端，多端同步
- **登录**：第三方 OAuth（GitHub / Microsoft / Twitter / GitLab / QQ），默认关闭，与账号密码登录互不影响
- **快捷键**：`空格` 播放/暂停，`←` `→` ±5 秒（`Shift` 30 秒），`↑` `↓` 音量，`Esc` 关闭弹层
- **移动端**：适配各类窄屏、横屏、分屏，自动调整边距和排布

## 部署

**方式一 · Git 导入（推荐）**

1. Fork 本仓库。
2. Cloudflare Dashboard → **Workers & Pages** → **Create** → **Worker** → **Import a repository**，连 Git，选仓库，分支和构建设置都用默认。
3. **Save and Deploy**。

**方式二 · Wrangler 部署**

```bash
npm install
node build.js
npx wrangler deploy
```

改样式或前端逻辑一律改 `index.html`，改完跑一次 `node build.js` 重新生成 `worker.js`。

### 开通账号 / 收藏 / 云歌单（绑定 D1，可选但推荐）

搜索和播放不需要数据库；**想要注册登录、收藏、歌单跟随账号**，就要绑定一个免费的 Cloudflare D1。

**Wrangler 方式：**

```bash
# 1. 创建 D1 数据库（免费额度足够个人使用）
npx wrangler d1 create music-db
#    命令会输出一个 database_id（一长串 UUID）。
# 2. 打开 wrangler.toml，找到文末被注释掉的 [[d1_databases]] 四行，去掉注释，
#    把 database_id 改成上一步的真实 id。
# 3. 初始化表结构（可跳过：Worker 第一次收到请求时会自动 CREATE TABLE IF NOT EXISTS）
npx wrangler d1 execute music-db --remote --file=./schema.sql
# 4. 重新部署
npx wrangler deploy
```

> 为保证「没建 D1 也能直接部署」，`wrangler.toml` 里的 `[[d1_databases]]` 绑定**默认是注释掉的**；不启用也能正常部署，只是账号/收藏功能自动隐藏。**不想改文件就用上面的 Dashboard 方式直接绑定（绑定名 `DB`）。**

**Dashboard 方式（含 Git 导入）：**

1. **Workers & Pages → D1 SQL Database → Create**，数据库名可填 `music-db`。
2. 进入你的 Worker → **Settings → Bindings → Add → D1 Database**，绑定名（Variable name）必须填 **`DB`**，选刚建的库。
3. 保存后重新部署即可；表结构会在首次访问时自动创建。

绑定成功后，刷新页面顶栏会出现「登录」，点进去可注册账号；注册成功自动拥有默认歌单「我的收藏」，搜索结果点 ♥ 即可收藏，也可在「我的音乐 → 我的收藏」里新建歌单、播放整单。**不绑定 D1 时这些接口统一回 503，前端自动隐藏入口，其余功能不受影响。**

## 环境变量

> Dashboard → **Workers & Pages** → 你的 Worker → **Settings** → **Variables and Secrets** → **Add variable**

| 变量 | 类型 | 值（默认） | 说明 |
|---|---|---|---|
| `OAUTH_ON` | Text | / | **【注意】此变量仅本人开启时有效，后台链接 Oauth 登录授权平台** <br>状态为 OFF 时：无登录按钮、不支持 OAuth 回调、不存播放进度、不显示账号列表<br>「我的音乐」功能不受影响 |
| `MUSIC_TOKEN` | Secret | / | 上游 API 鉴权 token（HMAC-SHA1）。留空则匿名访问 |

## 文件 & 后端路由

| 文件 | 作用 |
|---|---|
| `index.html` | 页面源文件，**改样式和前端逻辑改这里** |
| `build.js` | 把 `index.html` + 后端骨架打包成 `worker.js` |
| `worker.js` | 部署入口，自动生成，勿手改 |
| `wrangler.toml` | 部署配置（含 D1 绑定） |
| `schema.sql` | D1 表结构（users / sessions / playlists / playlist_songs），可选手动初始化 |

| 路由 | 作用 |
|---|---|
| `/api` | 搜索 / 榜单 / 歌单 JSON |
| `/resolve` | 只解出音频 / 封面地址（`{ url, server, id, type, via }`），播放器主用 |
| `/stream` `/cover` | 307 跳转到地址 |
| `/lyric` | 歌词文本 |
| `/sources` | 音源可用性检测，结果缓存 30 分钟 |
| `/health` | 诊断接口能否解出地址，**不下载音频** |
| `/config` | 回 `{ "oauth": true\|false, "account": true\|false }`（`account` 表示是否绑定 D1） |
| `/auth/register` `/auth/login` | 注册 / 登录，返回 `{ token, username }` |
| `/auth/me` `/auth/logout` | 校验当前会话 / 退出（`Authorization: Bearer <token>`） |
| `/my/playlists` | `GET` 取当前账号全部歌单（含歌曲）；`POST` 新建歌单 |
| `/my/playlists/delete` | 删除自建歌单（默认歌单不可删） |
| `/my/songs/add` `/my/songs/remove` | 把歌曲收藏进 / 移出某歌单 |

## License
MIT
