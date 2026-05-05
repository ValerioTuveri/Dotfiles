# -------------------------------------------------------------------
# Encoding
# -------------------------------------------------------------------
try
{
  [Console]::InputEncoding = [System.Text.Encoding]::UTF8
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  chcp 65001 > $null
} catch
{
}

# -------------------------------------------------------------------
# Core helpers
# -------------------------------------------------------------------
function ll
{
  Get-ChildItem -Force @args
}

function touch
{
  param([string]$path)

  if (Test-Path $path)
  {
    (Get-Item $path).LastWriteTime = Get-Date
  } else
  {
    New-Item -ItemType File -Path $path | Out-Null
  }
}

function which
{
  param([string]$cmd)

  Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function grep
{
  $input | Select-String @args
}

function base64
{
  param(
    [Parameter(ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [string]$InputObject
  )

  process
  {
    [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputObject))
  }
}

function unbase64
{
  param(
    [Parameter(ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [string]$InputObject
  )

  process
  {
    [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($InputObject))
  }
}

function reload
{
  . $PROFILE
}

# -------------------------------------------------------------------
# Interactive shell customization
# -------------------------------------------------------------------
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected)
{
  Clear-Host

  if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)
  {
    try
    {
      Set-PSReadLineOption -HistorySearchCursorMovesToEnd
      Set-PSReadLineOption -ShowToolTips
      Set-PSReadLineOption -PredictionSource History
      Set-PSReadLineOption -PredictionViewStyle ListView

      Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
      Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
      Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

      Set-PSReadLineKeyHandler -Key 'Ctrl+v' -ScriptBlock {
        $clipboard = Get-Clipboard -Raw
        $converted = $clipboard -replace '\\(\s*(\r\n|\r|\n))', "`$1"
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($converted)
      }
    } catch
    {
    }
  }

  if (Get-Module -ListAvailable Microsoft.WinGet.CommandNotFound)
  {
    Import-Module -Name Microsoft.WinGet.CommandNotFound
  }

  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue)
  {
    $ompTheme = Join-Path $PSScriptRoot 'oh-my-posh\themes\catppuccin.omp.json'
    if (Test-Path $ompTheme)
    {
      oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
  }

  $fastfetchConfig = Join-Path $PSScriptRoot '.config\fastfetch\config.jsonc'
  if (-not (Test-Path $fastfetchConfig))
  {
    $fastfetchConfig = Join-Path $HOME '.config\fastfetch\config.jsonc'
  }

  $fastfetchCmd = Get-Command fastfetch -ErrorAction SilentlyContinue
  if ($fastfetchCmd -and (Test-Path $fastfetchConfig))
  {
    fastfetch -c $fastfetchConfig
  }

  # -------------------------------------------------------------------
  # Prompt banner
  # -------------------------------------------------------------------
  $green = "`e[38;2;166;209;137m"
  $yellow = "`e[38;2;229;200;144m"
  $mauve = "`e[38;2;202;158;230m"
  $pink = "`e[38;2;244;184;228m"
  $peach = "`e[38;2;239;159;118m"
  $reset = "`e[0m"

  $culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
  $date = (Get-Date).ToString("dddd, MMMM dd yyyy", $culture)
  $time = Get-Date -Format "HH:mm"

  Write-Host ""
  Write-Host " $green◆$reset  $yellow$date$reset  $mauve$time$reset"

  $quotes = @(
    "Code is like humor. When you have to explain it, it's bad."
    "First, solve the problem. Then, write the code."
    "Simplicity is the ultimate sophistication."
    "Programs must be written for people to read, not machines to execute."
    "The best code is no code at all."
    "Debugging is twice as hard as writing the code in the first place."
    "If it works, don't touch it."
    "There is no place for magic in production code."
    "Perfection is achieved when there is nothing left to remove."
    "A good developer looks both ways before crossing a one-way street."
  )

  $quote = $quotes | Get-Random
  Write-Host " $pink◆$reset  $peach$quote$reset"
  Write-Host ""
}

# -------------------------------------------------------------------
# Small conveniences
# -------------------------------------------------------------------
Set-Alias -Name open -Value ii -Force

# -------------------------------------------------------------------
# Completion cache
# -------------------------------------------------------------------
$kubectlCache = Join-Path $env:TEMP 'kubectl_completion.ps1'
$kubectlCmd = Get-Command kubectl -ErrorAction SilentlyContinue
if ($kubectlCmd)
{
  if (-not (Test-Path $kubectlCache) -or
    (Get-Item $kubectlCmd.Source).LastWriteTime -gt (Get-Item $kubectlCache).LastWriteTime)
  {
    kubectl completion powershell | Out-String | Set-Content $kubectlCache -Encoding UTF8
  }

  . $kubectlCache
}
