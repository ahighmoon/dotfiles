# =============================================================================
# PowerShell Shared Profile (managed by chezmoi at ~/.config/powershell/profile.ps1)
# Loaded by both PowerShell 7 (pwsh) and Windows PowerShell 5.1 (powershell)
# =============================================================================

# 1. UTF-8 编码（避免中文、Nerd Font 图标和管道乱码）
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()

# 2. PSReadLine：对齐 Mac/WSL 下 zsh-autosuggestions + zsh-syntax-highlighting + 按词跳转体验
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
    # PowerShell 7+ (PSReadLine >= 2.1) 开启历史命令灰字自动预测
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle InlineView
    }

    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -HistoryNoDuplicates

    # 语法高亮配色（对齐 GitHub Dark）
    Set-PSReadLineOption -Colors @{
        Command            = '#79C0FF'
        Parameter          = '#D2A8FF'
        Operator           = '#FF7B72'
        Variable           = '#FFA657'
        String             = '#A5D6FF'
        Number             = '#79C0FF'
        Type               = '#FFA657'
        Comment            = '#8B949E'
        InlinePrediction   = '#6E7681'
    }

    # 按词跳转 & 按词接受灰字补全（对齐 dot_zshrc 的 Option/Alt + ←/→ 与 Ctrl + ←/→）
    Set-PSReadLineKeyHandler -Chord 'Alt+RightArrow'  -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Alt+f'           -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Alt+LeftArrow'   -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Alt+b'           -Function BackwardWord

    # 上下方向键按当前已输入前缀搜索历史（比如输入 git 后按 ↑ 只翻找 git 开头的历史）
    Set-PSReadLineKeyHandler -Chord 'UpArrow'         -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord 'DownArrow'       -Function HistorySearchForward
}

# 3. 闲置时异步加载重量级模块（posh-git 约 480ms、Chocolatey 约 160ms），让首屏秒开（<50ms）
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    $winPsModules = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
    if ((Test-Path $winPsModules) -and ($env:PSModulePath -notlike "*$winPsModules*")) {
        $env:PSModulePath = "$env:PSModulePath;$winPsModules"
    }
    Import-Module posh-git -Global -ErrorAction SilentlyContinue

    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $ChocolateyProfile) {
        Import-Module "$ChocolateyProfile" -Global -ErrorAction SilentlyContinue
    }
}

# 6. 常用顺手别名（对齐 Unix/macOS 习惯）
function which ($cmd) { Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function open ($path = '.') { Invoke-Item $path }

# 7. 本机私有配置（凭据、本机专用路径等）放在 ~/.profile.local.ps1，不进仓库
if (Test-Path "$HOME\.profile.local.ps1") {
    . "$HOME\.profile.local.ps1"
}
