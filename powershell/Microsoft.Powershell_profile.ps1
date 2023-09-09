oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
function SetupMSVC {
    param (
        [PSDefaultValue(Help = "x64")]
        [string]$Arch = "x64",
        [PSDefaultValue(Help = "false")]
        [switch]$Pre
    )

    $moduleAlreadyLoaded = Get-Module Microsoft.VisualStudio.DevShell
    if ($moduleAlreadyLoaded) {
        Write-Error "Module with the same name already loaded, cannot load another one because there will be assemblies conflicts"
        return
    }
    $assemblyPresent = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -like '*Microsoft.VisualStudio.DevShell*' }
    if ($assemblyPresent) {
        Write-Error "Assembly with the same name already loaded, cannot load another one because there will be assemblies conflicts"
        return
    }

    if ($Pre) {
        $vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -prerelease -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath
    } else {
        $vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath
    }
    $commonLocation = "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    if (Test-Path $commonLocation) {
        $dllPath = $commonLocation
    } else {
        $dllPath = (Get-ChildItem $vsPath -Recurse -File -Filter Microsoft.VisualStudio.DevShell.dll).FullName
    }
    Import-Module -Force $dllPath
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments "-arch=$Arch"
}

function time {
    $cmd = $args | Join-String -Separator " "
    $output = Measure-Command { Invoke-Expression $cmd }
    return $output.TotalSeconds
}

function np {
    param (
        [string]$filename
    )
    & "${env:ProgramFiles}\Notepad++\notepad++.exe" $filename
}

function grepall {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Pattern,
        [string]$Path = "."
    )
    Get-ChildItem -File -Path $path -Recurse | Select-String -Pattern $pattern
}

function restart-razer {
    $processOptions = @{
        FilePath = "pwsh"
        ArgumentList = "-Command","Get-Process | Where-Object { `$_.ProcessName -like '*Razer*' } | ForEach-Object { Stop-Process -Force `$_ }"
        Verb = "RunAs"
        WindowStyle = "Hidden"
        Wait = $true
    }
    Start-Process @processOptions
	Start-Process -FilePath "${env:ProgramFiles(x86)}\Razer\Synapse3\WPFUI\Framework\Razer Synapse 3 Host\Razer Synapse 3.exe"
}

function wget {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [string]$OutFile = $null
    )
    if (($null -eq $OutFile) -or ($OutFile -eq "")) {
        $FileName = $Url.Split("/")[-1]
        $OutFile = [System.Net.WebUtility]::UrlDecode($FileName)
    }
    Write-Output "Writing output to $OutFile"
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $Url -UseBasicParsing -OutFile $OutFile
    $ProgressPreference = $oldProgressPreference
}

function format-source {
	param(
		[Parameter(Mandatory=$true)][string]$fmtpath,
		[Parameter(Mandatory=$false)][string[]]$Exclude=@()
	)
    if ($null -eq (Get-Command "clang-format.exe" -ErrorAction SilentlyContinue)) {
        Write-Output "clang-format.exe not found, please install it and/or add it to PATH."
        return
    }
	Write-Output "Excluding: $Exclude"
	$totalFormatted = 0
	$h_files = Get-ChildItem -Path $fmtpath -Exclude $Exclude 
    foreach ($file in $h_files) {
		if ((Test-Path -Path $file -PathType leaf) -and ($file.FullName.EndsWith(".h"))) {
			Write-Output "Formatting $file" 
			clang-format.exe -i -style=file $file.FullName
			$totalFormatted += 1
		} elseif (Test-Path -Path $file -PathType Container) {
			$childPath = $file
			$inner_h_files = Get-ChildItem -Path $childPath -Recurse -Filter *.h
            foreach ($inner_file in $inner_h_files) { 
				$name = $inner_file.FullName
				Write-Output "Formatting $inner_file" 
				clang-format.exe -i -style=file $name
				$totalFormatted += 1
			}
		}
	}
	$cpp_files = Get-ChildItem -Path $fmtpath -Exclude $Exclude 
    foreach ($file in $cpp_files) {
		if ((Test-Path -Path $file -PathType leaf) -and ($file.FullName.EndsWith(".cpp"))) {
			Write-Output "Formatting $file" 
			clang-format.exe -i -style=file $file.FullName
			$totalFormatted += 1
		} elseif (Test-Path -Path $file -PathType Container) {
			$childPath = $file
			$inner_cpp_files = Get-ChildItem -Path $childPath -Recurse -Filter *.cpp
            foreach ($inner_file in $inner_cpp_files) { 
				$name = $inner_file.FullName
				Write-Output "Formatting $inner_file" 
				clang-format.exe -i -style=file $name
				$totalFormatted += 1
			}
		}
	}
	Write-Output "All done, formatted $totalFormatted files."
}