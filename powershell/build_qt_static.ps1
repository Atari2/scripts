param(
    [Parameter(Mandatory=$true)][string]$qtInstallDir,
    [Parameter(Mandatory=$true)][string]$qtVersion
)

function LoadVsDevShell {
    $Arch = "x64"
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

$modulesToSkip = @(
    '-skip', 'qtwayland',
    '-skip', 'qtwebengine',
    '-skip', 'qtwebview',
    '-skip', 'qttranslations',
    '-skip', 'qtwebsockets',
    '-skip', 'qtwebchannel',
    '-skip', 'qtmqtt',
    '-skip', 'qtnetwork',
    '-skip', 'qtquick',
    '-skip', 'qtquickcontrols2',
    '-skip', 'qtwebkit',
    '-skip', 'qtwebkitwidgets',
    '-skip', 'qtquicktimeline',
    '-skip', 'qtquick3d',
    '-skip', 'qtdoc',
    '-skip', 'qtinsighttracker',
    '-skip', 'qtlocation',
    '-skip', 'qtlottie',
    '-skip', 'qtopcua',
    '-skip', 'qtqmlscriptcompiler',
    '-skip', 'qtquick3dphysics',
    '-skip', 'qtquickeffectmaker',
    '-skip', 'qtscxml',
    '-skip', 'qtvirtualkeyboard',
    '-skip', 'qtvncserver',
    '-skip', 'qtremoteobjects',
    '-skip', 'qtmultimedia',
    '-skip', 'qthttpserver',
    '-skip', 'qt3d',
    '-skip', 'qtcharts',
    '-skip', 'qtdatavis3d',
    '-skip', 'qtspeech'
)
Push-Location
Set-Location C:\Qt\$qtVersion\Src
LoadVsDevShell
Set-Variable -Name _ROOT -Value "C:\Qt\$qtVersion\Src"
$env:PATH += ";$_ROOT\qtbase\bin";
Set-Variable -Name _ROOT -Value ""
.\configure -prefix "$qtInstallDir" -nomake examples -nomake tests $modulesToSkip -release -static
cmake --build . --parallel
cmake --install .
cmake --build . --target clean
Get-ChildItem -Filter "CMakeFiles" -Recurse -Directory | Remove-Item -Recurse -Force
Pop-Location