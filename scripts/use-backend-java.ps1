<##
.SYNOPSIS
Configures the current PowerShell process to run Smart Aid backend commands on Java 21 or newer.

.DESCRIPTION
Smart Aid is compiled for Java 21.  This helper prefers SMARTAID_JAVA_HOME when supplied,
then a Java 21 installation, and finally any newer compatible JDK discovered in the usual
Windows installation folders.  It only changes the calling process; it never changes the
machine-wide Java configuration.
##>

$ErrorActionPreference = 'Stop'

function Get-SmartAidJavaMajorVersion([string]$javaExecutable) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $versionOutput = & cmd /c "`"$javaExecutable`" -version 2>&1"
        $versionString = $versionOutput -join "`n"
        $match = [regex]::Match($versionString, 'version\s+"(?<version>\d+)(?:\.|\")')
        if (-not $match.Success) {
            return $null
        }
        return [int]$match.Groups['version'].Value
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Find-SmartAidBackendJavaHome {
    $candidateHomes = [System.Collections.Generic.List[string]]::new()
    foreach ($candidate in @($env:SMARTAID_JAVA_HOME, $env:JAVA_HOME)) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $candidateHomes.Add($candidate)
        }
    }

    foreach ($root in @('C:\Program Files\Microsoft', 'C:\Program Files\Eclipse Adoptium', 'C:\Program Files\Java')) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $candidateHomes.Add($_.FullName) }
        }
    }

    $compatible = foreach ($candidate in ($candidateHomes | Select-Object -Unique)) {
        $javaExecutable = Join-Path $candidate 'bin\java.exe'
        if (-not (Test-Path -LiteralPath $javaExecutable)) {
            continue
        }

        $major = Get-SmartAidJavaMajorVersion $javaExecutable
        if ($null -ne $major -and $major -ge 21) {
            [PSCustomObject]@{ Home = $candidate; Major = $major }
        }
    }

    if (-not $compatible) {
        throw 'Smart Aid backend requires Java 21 or newer. Install a compatible JDK or set SMARTAID_JAVA_HOME.'
    }

    # Prefer the project's Java 21 target over an arbitrary newer JDK, then use the newest compatible fallback.
    return ($compatible | Sort-Object @{ Expression = { if ($_.Major -eq 21) { 0 } else { 1 } } }, @{ Expression = 'Major'; Descending = $true } | Select-Object -First 1).Home
}

$script:SmartAidBackendJavaHome = Find-SmartAidBackendJavaHome
$env:JAVA_HOME = $script:SmartAidBackendJavaHome
$env:Path = "$(Join-Path $script:SmartAidBackendJavaHome 'bin');$env:Path"
