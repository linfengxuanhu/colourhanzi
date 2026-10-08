# 汉字找字涂色 App V2

## GitHub 自动打包

真正的 GitHub Actions 配置位于：

`.github/workflows/build-apk.yml`

GitHub 会自动识别它。根目录同时放了一份 `build-apk.yml` 方便在安卓文件管理器里确认。

### 上传
将项目根目录中的全部内容上传到 GitHub 仓库，保留 `.github/workflows/build-apk.yml`。

如果安卓文件管理器不显示 `.github`：
- GitHub 网页端可以直接建立 `.github/workflows/build-apk.yml`
- 或使用支持显示隐藏目录的文件管理器。

### 手动运行
GitHub 仓库：
Actions → Build Android APK → Run workflow

完成后：
Actions → 对应运行记录 → Artifacts → hanzi-color-app-v2-apk
