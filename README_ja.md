# LaTeX Release Action

🚀 **LaTeX文書を自動ビルドし、GitHub Releasesを作成する高性能なGitHub Action**

[![CI Tests](https://github.com/smkwlab/latex-release-action/actions/workflows/test.yml/badge.svg)](https://github.com/smkwlab/latex-release-action/actions/workflows/test.yml)
[![GitHub release](https://img.shields.io/github/release/smkwlab/latex-release-action.svg)](https://github.com/smkwlab/latex-release-action/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) | 日本語

## ✨ 機能

- 📄 **複数ファイル対応**: 1つのワークフローで複数のLaTeX文書をビルド
- ⚡ **並列処理**: 高速コンパイルのためのオプション並列ビルド
- 🛡️ **セキュリティ強化**: 入力値の検証とサニタイゼーション
- 🧹 **スマートクリーンアップ**: 設定可能な中間ファイルクリーンアップ
- 📦 **自動リリース**: コンパイル済みPDFでGitHub Releasesを自動作成
- 🎯 **柔軟なオプション**: カスタマイズ可能なLaTeXコンパイルオプション
- 🏃‍♂️ **高性能**: 最適化されたコンテナベース実行
- 🌏 **日本語サポート**: 日本語完全対応のTeXLive環境

## 🚀 クイックスタート

### 基本的な使用方法

`.github/workflows/latex-build.yml`を作成：

```yaml
name: LaTeX Build and Release

on:
  push:
    tags: ['*']  # すべてのタグで起動
  pull_request:
    branches: [ main ]

jobs:
  build-latex:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    permissions:
      contents: write  # リリース作成に必要
    steps:
      - name: Build and Release LaTeX
        uses: smkwlab/latex-release-action@v2
        with:
          files: "document"  # document.texをビルド
```

### 高度な使用方法

```yaml
name: Advanced LaTeX Build

on:
  push:
    tags: ['*']  # すべてのタグ（例：release-1.0, draft-v2, final）
  pull_request:
    branches: [ main ]

jobs:
  build-latex:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    permissions:
      contents: write
    steps:
      - name: Build Multiple LaTeX Files
        uses: smkwlab/latex-release-action@v2
        with:
          files: "paper, appendix, presentation"
          parallel: "true"                              # 並列ビルドを有効化
          latex_options: "-pdf -interaction=nonstopmode -halt-on-error"
          cleanup: "true"                               # 中間ファイルをクリーンアップ
          release_name: "Research Paper ${{ github.ref_name }}"
```

## 📋 入力パラメータ

| パラメータ | 必須 | デフォルト | 説明 |
|-----------|------|-----------|------|
| `files` | ✅ | - | カンマ区切りのLaTeXファイル名（.tex拡張子なし） |
| `latex_options` | ❌ | `-pdf -interaction=nonstopmode` | カスタムlatexmkコンパイルオプション |
| `parallel` | ❌ | `false` | 複数ファイルの並列ビルドを有効化 |
| `cleanup` | ❌ | `true` | ビルド後に中間ファイルを削除 |
| `release_name` | ❌ | 自動生成 | GitHub Releaseのカスタム名 |

## 🎯 使用例

### 学術論文リポジトリ

```yaml
name: Academic Paper Build
on:
  push:
    tags: ['*']  # paper-v1, submission-final など
jobs:
  build-paper:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    permissions:
      contents: write
    steps:
      - name: Build Research Paper
        uses: smkwlab/latex-release-action@v2
        with:
          files: "paper/main, appendix/supplementary"
          parallel: "true"
          latex_options: "-pdf -interaction=nonstopmode -halt-on-error"
          release_name: "Paper Draft ${{ github.ref_name }}"
```

### 複数文書プロジェクト

```yaml
name: Multi-Document Build
on:
  push:
    tags: ['*']  # thesis-draft, final-submission など
jobs:
  build-documents:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    permissions:
      contents: write
    steps:
      - name: Build All Documents
        uses: smkwlab/latex-release-action@v2
        with:
          files: "thesis, slides, poster, abstract"
          parallel: "true"
          cleanup: "true"
```

### 依存関係のある逐次ビルド

```yaml
name: Sequential Document Build
on:
  push:
    tags: ['*']  # report-draft, monthly-update など
jobs:
  build-reports:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    permissions:
      contents: write
    steps:
      - name: Build with Dependencies
        uses: smkwlab/latex-release-action@v2
        with:
          files: "main-report, summary-report"
          parallel: "false"  # 逐次ビルド
          latex_options: "-pdf -interaction=nonstopmode"
```

## 📂 ファイル構成例

### シンプルなプロジェクト
```
your-repo/
├── .github/workflows/latex-build.yml
├── document.tex
├── references.bib
└── images/
    └── figure1.png
```

### 複雑なプロジェクト
```
your-repo/
├── .github/workflows/latex-build.yml
├── paper/
│   ├── main.tex
│   ├── sections/
│   └── references.bib
├── slides/
│   └── presentation.tex
└── appendix/
    └── supplementary.tex
```

**サブディレクトリの使用方法:**
```yaml
with:
  files: "paper/main, slides/presentation, appendix/supplementary"
```

## 🔄 リリース動作

### プルリクエスト
- 🔨 検証のためにLaTeX文書をビルド
- 📋 `{ブランチ名}-release`タグで**プレリリース**を作成
- ✅ メインリリースに影響せずにコンパイルを検証

### タグプッシュ
- 🚀 本番用のLaTeX文書をビルド
- 📦 `{タグ名}-release`タグで**リリース**を作成
- 📄 コンパイル済みPDFを自動添付

### 生成されるリリース内容
```markdown
## 📄 LaTeX Build Results

This release contains compiled PDF files from the following LaTeX sources:

**Built files:** paper, appendix, presentation
**Build options:** `-pdf -interaction=nonstopmode`
**Parallel build:** true
**Cleanup performed:** true

🤖 *This release was automatically generated by LaTeX Release Action*
```


## 🔧 要件

### 権限設定
```yaml
permissions:
  contents: write  # GitHub Releasesの作成に必要
```

### コンテナサポート
**推奨アプローチ**: 最適なパフォーマンスのためプリビルドTexLiveコンテナを使用：

```yaml
jobs:
  build-latex:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine  # 推奨
    permissions:
      contents: write
    steps:
      - uses: smkwlab/latex-release-action@v2
        with:
          files: "document"
```

**代替コンテナ:**
- `texlive/texlive:latest` - 公式TexLive
- `pandoc/latex:latest` - 軽量オプション
- `latexmk`がインストールされたカスタムコンテナ

### ファイル名のセキュリティ
セキュリティのため、ファイル名に使用できる文字：
- 英数字：`a-z`, `A-Z`, `0-9`
- 特殊文字：`_`, `-`, `/`


## 🛠️ 開発・テスト

### ローカルテスト
```bash
# リポジトリのクローン
git clone https://github.com/smkwlab/latex-release-action.git
cd latex-release-action

# テスト実行
./test.sh                # 全テスト
./test.sh logic          # クイック検証
./test.sh local          # ローカルLaTeXテスト
./test.sh docker         # コンテナテスト
```

### テストカバレッジ
- ✅ 単一ファイルビルド
- ✅ 複数ファイルビルド（並列・逐次）
- ✅ 存在しないファイルのエラーハンドリング
- ✅ コンテナベース実行
- ✅ GitHub Actions エミュレーション

## 🤝 コントリビューション

コントリビューションを歓迎します！[コントリビューションガイドライン](CONTRIBUTING.md)をご確認ください。

### 開発ワークフロー
1. 🔀 リポジトリをフォーク
2. 🌿 機能ブランチを作成
3. ✅ 新機能のテストを追加
4. 🧪 テストスイートを実行
5. 📝 ドキュメントを更新
6. 🚀 プルリクエストを送信

## 📜 ライセンス

このプロジェクトはMITライセンスの下で公開されています - 詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 👥 作者・謝辞

- **メンテナンス**: [下川研究室](https://github.com/smkwlab)
- **コントリビューター**: [コントリビューター一覧](https://github.com/smkwlab/latex-release-action/graphs/contributors)
- **特別感謝**: フィードバックとバグレポートを提供してくださったすべてのユーザー

## 📞 サポート

- 📖 **ドキュメント**: [GitHub Wiki](https://github.com/smkwlab/latex-release-action/wiki)
- 🐛 **バグ報告**: [GitHub Issues](https://github.com/smkwlab/latex-release-action/issues)
- 💡 **機能リクエスト**: [GitHub Discussions](https://github.com/smkwlab/latex-release-action/discussions)

---

⭐ **このリポジトリが役に立った場合はスターをお願いします！**

📄 **最適用途**: 学術論文、論文、技術レポート、プレゼンテーション、およびあらゆるLaTeXベースのドキュメントワークフロー。