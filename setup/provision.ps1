<#
.SYNOPSIS
    Creates and seeds the five SQL Server databases the Flyway pipeline needs.

.DESCRIPTION
    Build  - created empty. The build pipeline cleans and rebuilds it every run.
    Check  - created empty. Used as the clean comparison target for 'flyway check'.
    QA     - seeded with Northwind. Represents a deployed environment.
    Prod1  - seeded with Northwind. Represents a deployed environment.
    Prod2  - seeded with Northwind. Represents a deployed environment.

    The three seeded databases end up at the state described by baseline migration B001,
    so the pipeline baselines them there and applies V002 onward as pending work.

.EXAMPLE
    .\provision.ps1 -Password (Read-Host -AsSecureString "sa password")

.EXAMPLE
    .\provision.ps1 -Server "localhost" -User "sa" -Force
#>

[CmdletBinding()]
param(
    [string] $Server = 'localhost',

    [string] $User = 'sa',

    # Prompted for securely if omitted. Never hard-code this.
    [Parameter(Mandatory = $true)]
    [System.Security.SecureString] $Password,

    [string] $Prefix = 'Northwind',

    # Path to the Microsoft Northwind script.
    [string] $NorthwindScript = "$env:USERPROFILE\Downloads\NorthWind.sql",

    # Drop and recreate the databases if they already exist.
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# --- Preflight -------------------------------------------------------------

$sqlcmd = Get-Command sqlcmd.exe -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    throw "sqlcmd.exe not found on PATH. Install the SQL Server command line tools, or open a 'Developer Command Prompt' that has them."
}

if (-not (Test-Path -LiteralPath $NorthwindScript)) {
    throw "Northwind script not found at '$NorthwindScript'. Pass -NorthwindScript with the correct path."
}

$plainPassword = [System.Net.NetworkCredential]::new('', $Password).Password

$empty  = @("$($Prefix)_Build", "$($Prefix)_Check")
$seeded = @("$($Prefix)_QA", "$($Prefix)_Prod1", "$($Prefix)_Prod2")
$all    = $empty + $seeded

function Invoke-Sql {
    param(
        [Parameter(Mandatory)] [string] $Query,
        [string] $Database = 'master'
    )
    # -b makes sqlcmd return a non-zero exit code on error so we can detect failures.
    & sqlcmd.exe -S $Server -U $User -P $plainPassword -d $Database -b -Q $Query
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed (exit $LASTEXITCODE) running against '$Database'." }
}

function Invoke-SqlFile {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Database
    )
    & sqlcmd.exe -S $Server -U $User -P $plainPassword -d $Database -b -i $Path
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed (exit $LASTEXITCODE) running '$Path' against '$Database'." }
}

Write-Host "Connecting to $Server as $User..." -ForegroundColor Cyan
Invoke-Sql -Query "SELECT @@VERSION"

# --- Create databases ------------------------------------------------------

foreach ($db in $all) {
    $exists = & sqlcmd.exe -S $Server -U $User -P $plainPassword -d master -b -h -1 -W `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$db'"

    if ($exists -match '1') {
        if (-not $Force) {
            Write-Host "  $db already exists - skipping. Use -Force to drop and recreate." -ForegroundColor Yellow
            continue
        }
        Write-Host "  Dropping $db..." -ForegroundColor Yellow
        Invoke-Sql -Query "ALTER DATABASE [$db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db];"
    }

    Write-Host "  Creating $db..." -ForegroundColor Green
    Invoke-Sql -Query "CREATE DATABASE [$db];"
}

# --- Seed the deployed environments ---------------------------------------

foreach ($db in $seeded) {
    $hasTables = & sqlcmd.exe -S $Server -U $User -P $plainPassword -d $db -b -h -1 -W `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables"

    if ($hasTables -match '^\s*0\s*$') {
        Write-Host "  Seeding $db with Northwind..." -ForegroundColor Green
        Invoke-SqlFile -Path $NorthwindScript -Database $db
    }
    else {
        Write-Host "  $db already has tables - leaving it alone." -ForegroundColor Yellow
    }
}

# --- Summary ---------------------------------------------------------------

Write-Host ""
Write-Host "Done. Current state:" -ForegroundColor Cyan
foreach ($db in $all) {
    $count = & sqlcmd.exe -S $Server -U $User -P $plainPassword -d $db -b -h -1 -W `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables"
    $role = if ($empty -contains $db) { 'should be empty' } else { 'seeded' }
    Write-Host ("  {0,-22} {1,3} tables  ({2})" -f $db, $count.Trim(), $role)
}

Write-Host ""
Write-Host "Next: add the GitHub Variables and Secrets listed in setup/README.md." -ForegroundColor Cyan
