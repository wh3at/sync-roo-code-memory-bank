# sync-roo-code-memory-bank

[GreatScottyMac/roo-code-memory-bank](https://github.com/GreatScottyMac/roo-code-memory-bank) からルールファイルを一括ダウンロードするためのPowerShellスクリプト。

ファイル一覧は`README.md`の表から自動取得する。

## 使用方法

```powershell
.\sync_roo_code_memory_bank.ps1 [-TargetDir <ダウンロード先ディレクトリ>]
```

### パラメータ

- `TargetDir`: ファイルのダウンロード先ディレクトリ（省略時はカレントディレクトリ）
