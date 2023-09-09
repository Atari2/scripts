try {
    $vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath
    Import-Module (Get-ChildItem $vsPath -Recurse -File -Filter Microsoft.VisualStudio.DevShell.dll).FullName
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x86'
} catch {
    Write-Output "Failed to enter VS Dev Shell: $_"
    Exit 1
}

try {
    git --version | Out-Null
} catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "This script requires git to be installed."
    Exit 1
}

try {
    nasm --version | Out-Null
} catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "This script requires nasm to be installed and on the path."
    Exit 1
}

$patchstring='
diff --git a/zsnes_1_51/src/makefile.ms b/zsnes_1_51/src/makefile.ms
index c1d8c2d..e335ad8 100644
--- a/zsnes_1_51/src/makefile.ms
+++ b/zsnes_1_51/src/makefile.ms
@@ -87,8 +87,8 @@ ifeq (${ENV},win32)
 endif
 
 ifeq (${ENV},msvc)
-  CFLAGSORIG=/nologo /Ox /G6 /c /EHsc
-  MSVCLIBS=zlib.lib libpng.lib wsock32.lib user32.lib gdi32.lib shell32.lib winmm.lib dinput8.lib dxguid.lib
+  CFLAGSORIG=/nologo /Ox /c /EHsc /MT /I"${LIB_INCLUDE_DIR}"
+  MSVCLIBS="${LIB_LIBRARY_DIR}\zlib.lib" "${LIB_LIBRARY_DIR}\libpng16.lib" wsock32.lib user32.lib gdi32.lib shell32.lib winmm.lib dinput8.lib dxguid.lib
   DRESOBJ=${WINDIR}/zsnes.res
   OS=__WIN32__
 endif
@@ -212,7 +212,7 @@ ifneq (${DEBUGGER},no)
     LIBS+= -lpdcur
   else
     LIBS+= -lpdcurses -ladvapi32
-    MSVCLIBS+= pdcurses.lib advapi32.lib
+    MSVCLIBS+= "${LIB_LIBRARY_DIR}\pdcurses.lib" advapi32.lib
   endif
 endif
 
@@ -298,7 +298,7 @@ else
 	 @echo /Fezsnesw.exe *.obj ${CPUDIR}\*.obj ${VIDEODIR}\*.obj ${CHIPDIR}\*.obj ${EFFECTSDIR}\*.obj ${DOSDIR}\*.obj ${WINDIR}\*.obj ${GUIDIR}\*.obj > link.vc
 	 @echo ${ZIPDIR}\*.obj ${JMADIR}\*.obj ${NETDIR}\*.obj ${MMLIBDIR}\*.obj >> link.vc
 	 @echo ${MSVCLIBS} >> link.vc
-	 cl /nologo @link.vc ${WINDIR}/zsnes.res /link
+	 cl /MT /nologo @link.vc ${WINDIR}/zsnes.res /link
 endif
 
 cfg${OE}: cfg.psr ${PSR}
@@ -493,7 +493,7 @@ ${OBJFIX}: objfix.c
 endif
 ${PSR}: parsegen.cpp
 ifeq (${ENV},msvc)
-	cl /nologo /EHsc /Fe$@ parsegen.cpp zlib.lib
+	cl /nologo /EHsc /MD /I"${LIB_INCLUDE_DIR}" /Fe$@ parsegen.cpp "${LIB_LIBRARY_DIR}\zlib.lib"
 	${DELETECOMMAND} parsegen.obj
 else
 ifeq (${ENV},dos)
'

$currentdir=($pwd)
$libpath = "$currentdir\libs\lib"
$includepath = "$currentdir\libs\include"
if (!$(Test-Path -Path "$pwd/libs")) {
    mkdir libs
}

# if libs/lib is already present and the zsnesw.exe is present
# then we assume that the build is already done and just rebuild zsnes
if ((Test-Path -Path $libpath) -and (Test-Path -Path $includepath) -and (Test-Path -Path "zsnesw.exe")) {
    Write-Output "zsnesw.exe already exists and the lib folder already exists, starting partial rebuild"
    Write-Output "If the intention was to initiate a full rebuild, please delete the zsnesw.exe executable and rerun the script"

    # just rebuild zsnes
    Set-Location .\zsnes_1_51\src
    $env:PATH = "$env:PATH;$currentdir/libs/bin"
    make -f makefile.ms PLATFORM=msvc LIB_INCLUDE_DIR=$includepath LIB_LIBRARY_DIR=$libpath
    Copy-Item .\zsnesw.exe "$currentdir/zsnesw.exe"
    Set-Location $currentdir
    Write-Output "Done"
    Exit 0
} else {
    Write-Output "Starting full build..."
}

Set-Location $currentdir
# zlib
Invoke-WebRequest "https://www.zlib.net/fossils/zlib-1.2.12.tar.gz" -OutFile "zlib.tar.gz"
tar -xvzf .\zlib.tar.gz
Set-Location .\zlib-1.2.12
mkdir build
Set-Location .\build
cmake -DCMAKE_INSTALL_PREFIX="$currentdir/libs"  -A Win32 ..
cmake --build . --config Release
cmake --install .
Set-Location $currentdir
Remove-Item -Path zlib.tar.gz
Remove-Item -Path zlib-1.2.12 -Recurse -Force

# libpng
Invoke-WebRequest -UserAgent "Wget" -Uri "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/lpng1637.zip" -OutFile "libpng.zip"
unzip libpng.zip
Set-Location .\lpng1637
mkdir build
Set-Location .\build
cmake -DCMAKE_INSTALL_PREFIX="$currentdir/libs" -DPNG_BUILD_ZLIB=ON -DZLIB_LIBRARY="$libpath/zlib.lib" -DZLIB_INCLUDE_DIR="$includepath" -A Win32 ..
cmake --build . --config Release
cmake --install .
Set-Location $currentdir
Remove-Item -Path libpng.zip
Remove-Item -Path lpng1637 -Recurse -Force

# pdcurses
Invoke-WebRequest -Uri "https://github.com/wmcbrine/PDCurses/archive/refs/tags/3.9.zip" -OutFile "pdcurses.zip"
unzip pdcurses.zip
Set-Location .\PDCurses-3.9\wincon
nmake /f Makefile.vc
Copy-Item .\pdcurses.lib "$currentdir/libs/lib/pdcurses.lib"
Set-Location $currentdir
Remove-Item -Path pdcurses.zip
Get-ChildItem -Path .\PDCurses-3.9\*.h -Recurse | Move-Item -Destination .\libs\include -Force
Remove-Item -Path .\PDCurses-3.9 -Recurse -Force

# zsnes
Invoke-WebRequest -Uri "https://fusoya.eludevisibility.org/emulator/download/zsnesw151-FuSoYa-8MB_R2src.zip" -OutFile "zsnes.zip"
unzip zsnes.zip
Remove-Item zsnes.zip
$patchstring | Out-File ".\zsnes_makefile.patch" 
git apply zsnes_makefile.patch
Set-Location .\zsnes_1_51\src

$env:PATH = "$env:PATH;$currentdir/libs/bin"
make -f makefile.ms PLATFORM=msvc LIB_INCLUDE_DIR=$includepath LIB_LIBRARY_DIR=$libpath
Copy-Item .\zsnesw.exe "$currentdir/zsnesw.exe"
Set-Location $currentdir
Remove-Item .\zsnes_makefile.patch
Copy-Item .\libs\bin\zlib1.dll "$currentdir/zlib1.dll"
Copy-Item .\libs\bin\libpng16.dll "$currentdir/libpng16.dll"

Write-Output "Done"