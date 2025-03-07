# エラーハンドリングを有効化
$ErrorActionPreference = "Stop"

# スクリプトが閉じないようにするための設定（スクリプトの先頭部分）
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "スクリプトを実行しています。終了するにはプロンプトでEnterキーを押してください..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}
else {
    # コンソールホスト以外（例：ダブルクリック実行時）はコンソールウィンドウで再実行
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$scriptPath`"" -Wait
            exit
        }
    }
    catch {
        # 再起動の試みが失敗した場合は通常通り続行
        Write-Host "注意: コンソールモードで実行できませんでした。ウィンドウが閉じる場合があります。" -ForegroundColor Red
    }
}

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDir = "."
)

# エラーハンドリングを有効化
$ErrorActionPreference = "Stop"

# ターゲットディレクトリの存在確認と作成
if (!(Test-Path -Path $TargetDir)) {
    try {
        New-Item -ItemType Directory -Path $TargetDir -Force
        Write-Host "指定されたディレクトリを作成しました: $TargetDir" -ForegroundColor Green
    }
    catch {
        Write-Host "ディレクトリの作成に失敗しました: $_" -ForegroundColor Red
        exit 1
    }
}

# エラー発生時にも処理を継続するためのトライキャッチブロックをメインに設定
try {
    # リポジトリ情報
    $RepoOwner = "GreatScottyMac"
    $RepoName = "roo-code-memory-bank"
    $Branch = "main"

    # ダウンロード先ディレクトリ（カレントディレクトリの場合は '.' を指定）
    $TargetDir = "."

    Write-Host "README.md からテーブル形式のファイルリンクを取得中..." -ForegroundColor Cyan

    # README.md をダウンロード
    $ReadmeUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/README.md"
    $ReadmeContent = Invoke-WebRequest -Uri $ReadmeUrl -UseBasicParsing | Select-Object -ExpandProperty Content

    # テーブル部分を抽出
    $TableLines = @()
    $CaptureTable = $false
    $TableStartPattern = '\| Mode \| Rule File \|'
    $TableEndPattern = '^$'

    foreach ($line in $ReadmeContent -split "`n") {
        if ($line -match $TableStartPattern) {
            $CaptureTable = $true
        }
        
        if ($CaptureTable) {
            $TableLines += $line
        }
        
        # 空行を見つけたらテーブル終了
        if ($CaptureTable -and $line -match $TableEndPattern) {
            break
        }
    }

    # ヘッダー行とヘッダー区切り行をスキップ
    $TableData = $TableLines | Select-Object -Skip 2

    # ファイルリンクとファイル名を格納する配列
    $FileLinks = @()
    $FileNames = @()

    foreach ($line in $TableData) {
        # Markdown の表から [タイトル](リンク) 形式のリンクを抽出
        if ($line -match '\|\s*\[`(.+?)`\]\((.+?)\)') {
            $fileName = $matches[1]
            $fileLink = $matches[2]
            
            # GitHub のリンクを raw コンテンツリンクに変換
            $rawLink = $fileLink -replace 'github\.com', 'raw.githubusercontent.com' -replace '/blob/', '/'
            
            $FileLinks += $rawLink
            $FileNames += $fileName
        }
    }

    if ($FileLinks.Count -eq 0) {
        Write-Host "警告: テーブルからファイルリンクを取得できませんでした。" -ForegroundColor Yellow
        throw "ファイルリンクが見つかりませんでした"
    }
    else {
        Write-Host "テーブルから取得したファイルリンク数: $($FileLinks.Count)" -ForegroundColor Green
    }

    Write-Host "GitHubリポジトリからファイルをダウンロードします..." -ForegroundColor Cyan

    # 各ファイルをダウンロード
    $errorOccurred = $false
    $errorMessages = @()

    for ($i = 0; $i -lt $FileLinks.Count; $i++) {
        $link = $FileLinks[$i]
        $name = $FileNames[$i]
        
        Write-Host "ダウンロード中: $name" -ForegroundColor Cyan
        Write-Host "  リンク: $link" -ForegroundColor Gray
        
        # ファイルをダウンロード
        try {
            Invoke-WebRequest -Uri $link -OutFile "$TargetDir\$name" -UseBasicParsing
            
            if (Test-Path "$TargetDir\$name") {
                Write-Host "? $name を正常にダウンロードしました" -ForegroundColor Green
            }
        }
        catch {
            $errorOccurred = $true
            $errorMsg = "?? $name のダウンロードに失敗しました: $_"
            $errorMessages += $errorMsg
            Write-Host $errorMsg -ForegroundColor Red
        }
    }

   if ($errorOccurred) {
        Write-Host "`n一部のファイルのダウンロードに問題がありました。上記のエラーメッセージを確認してください。" -ForegroundColor Yellow
    } else {
        Write-Host "`nすべてのファイルのダウンロードが完了しました" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n処理中にエラーが発生しました: $_" -ForegroundColor Red
}
finally {
    # スクリプトの終了時点で一時停止して、ユーザーがエラーメッセージを確認できるようにする
    Write-Host "`n処理が完了しました。Enterキーを押すと終了します..." -ForegroundColor Magenta
    
    # より確実な一時停止方法（複数の方法を組み合わせて確実に停止させる）
    cmd /c pause > $null
    Read-Host "続行するにはEnterキーを押してください" > $null
}
