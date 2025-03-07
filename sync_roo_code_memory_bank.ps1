param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDir = "."
)

# エラーハンドリングの設定
$ErrorActionPreference = "Stop"

# 関数: 環境の初期化と検証
function Initialize-Environment {
    param (
        [string]$Directory
    )
    
    if (!(Test-Path -Path $Directory)) {
        try {
            New-Item -ItemType Directory -Path $Directory -Force
            Write-Host "指定されたディレクトリを作成しました: $Directory" -ForegroundColor Green
        }
        catch {
            throw "ディレクトリの作成に失敗しました: $_"
        }
    }

    # スクリプトが閉じないようにするための設定
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "スクリプトを実行しています。終了するにはプロンプトでEnterキーを押してください..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    else {
        try {
            $scriptPath = $MyInvocation.MyCommand.Path
            if ($scriptPath) {
                Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$scriptPath`"" -Wait
                exit
            }
        }
        catch {
            Write-Host "注意: コンソールモードで実行できませんでした。ウィンドウが閉じる場合があります。" -ForegroundColor Red
        }
    }
}

# 関数: READMEからテーブル情報を解析
function Get-TableFromReadme {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$Branch
    )

    Write-Host "README.md からテーブル形式のファイルリンクを取得中..." -ForegroundColor Cyan

    $ReadmeUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/README.md"
    $ReadmeContent = Invoke-WebRequest -Uri $ReadmeUrl -UseBasicParsing | Select-Object -ExpandProperty Content

    # テーブル解析
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
        
        if ($CaptureTable -and $line -match $TableEndPattern) {
            break
        }
    }

    # ヘッダー行とヘッダー区切り行をスキップ
    $TableData = $TableLines | Select-Object -Skip 2

    return $TableData
}

# 関数: テーブルデータからファイル情報を抽出
function Get-FileInformation {
    param (
        [array]$TableData
    )

    $FileInfo = @()

    foreach ($line in $TableData) {
        if ($line -match '\|\s*\[`(.+?)`\]\((.+?)\)') {
            $fileName = $matches[1]
            $fileLink = $matches[2]
            
            # GitHub のリンクを raw コンテンツリンクに変換
            $rawLink = $fileLink -replace 'github\.com', 'raw.githubusercontent.com' -replace '/blob/', '/'
            
            $FileInfo += @{
                Name = $fileName
                Url = $rawLink
            }
        }
    }

    if ($FileInfo.Count -eq 0) {
        throw "テーブルからファイルリンクを取得できませんでした"
    }

    Write-Host "テーブルから取得したファイルリンク数: $($FileInfo.Count)" -ForegroundColor Green
    return $FileInfo
}

# 関数: ファイルのダウンロード
function Download-Files {
    param (
        [array]$FileInfo,
        [string]$OutputDirectory
    )

    Write-Host "GitHubリポジトリからファイルをダウンロードします..." -ForegroundColor Cyan
    $errorMessages = @()

    foreach ($file in $FileInfo) {
        Write-Host "ダウンロード中: $($file.Name)" -ForegroundColor Cyan
        Write-Host "  リンク: $($file.Url)" -ForegroundColor Gray
        
        try {
            Invoke-WebRequest -Uri $file.Url -OutFile "$OutputDirectory\$($file.Name)" -UseBasicParsing
            
            if (Test-Path "$OutputDirectory\$($file.Name)") {
                Write-Host "✓ $($file.Name) を正常にダウンロードしました" -ForegroundColor Green
            }
        }
        catch {
            $errorMsg = "✗ $($file.Name) のダウンロードに失敗しました: $_"
            $errorMessages += $errorMsg
            Write-Host $errorMsg -ForegroundColor Red
        }
    }

    return $errorMessages
}

# メイン処理
try {
    # 環境の初期化
    Initialize-Environment -Directory $TargetDir

    # リポジトリ情報
    $RepoOwner = "GreatScottyMac"
    $RepoName = "roo-code-memory-bank"
    $Branch = "main"

    # テーブルデータの取得と解析
    $TableData = Get-TableFromReadme -RepoOwner $RepoOwner -RepoName $RepoName -Branch $Branch
    $FileInfo = Get-FileInformation -TableData $TableData

    # ファイルのダウンロード
    $ErrorMessages = Download-Files -FileInfo $FileInfo -OutputDirectory $TargetDir

    # 結果の表示
    if ($ErrorMessages.Count -gt 0) {
        Write-Host "`n一部のファイルのダウンロードに問題がありました。上記のエラーメッセージを確認してください。" -ForegroundColor Yellow
    } else {
        Write-Host "`nすべてのファイルのダウンロードが完了しました" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n処理中にエラーが発生しました: $_" -ForegroundColor Red
}
finally {
    # スクリプトの終了時点で一時停止
    Write-Host "`n処理が完了しました。Enterキーを押すと終了します..." -ForegroundColor Magenta
    cmd /c pause > $null
    Read-Host "続行するにはEnterキーを押してください" > $null
}
