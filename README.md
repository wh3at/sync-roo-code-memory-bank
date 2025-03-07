# sync-roo-code-memory-bank

[GreatScottyMac/roo-code-memory-bank](https://github.com/GreatScottyMac/roo-code-memory-bank) からルールファイルを一括ダウンロードするためのPowerShellスクリプト。

ファイル一覧は`README.md`の表から自動取得する。

## 使用方法

```powershell
powershell -ExecutionPolicy Bypass -File sync_roo_code_memory_bank.ps1 -TargetDir "<ダウンロード先ディレクトリ>"
```

### パラメータ

- `TargetDir`: ファイルのダウンロード先ディレクトリ（省略時はカレントディレクトリ）

---

# sync-roo-code-memory-bank

PowerShell script to bulk download rule files from [GreatScottyMac/roo-code-memory-bank](https://github.com/GreatScottyMac/roo-code-memory-bank).
The file list is automatically retrieved from the table in `README.md`.

## Usage
```powershell
powershell -ExecutionPolicy Bypass -File sync_roo_code_memory_bank.ps1 -TargetDir "<download destination directory>"
```

### Parameters
- `TargetDir`: Directory to download files to (defaults to current directory if omitted)
