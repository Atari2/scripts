#!/usr/bin/env bash

if [[ -z "$QT_DIR" ]]; then
    echo "QT_DIR not set, please set it to the path of Qt installation, e.g. /home/user/Qt/6.6.3/gcc_64"
    exit 1
fi

QMAKE=$QT_DIR/bin/qmake
export QMAKE

# clone repo
git clone https://github.com/Atari2/CFGEditorPlusPlus
cd CFGEditorPlusPlus || exit
CFGEditorDir=$(pwd)
mkdir build
cd build || exit

# download appimage tools
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20240109-1/linuxdeploy-x86_64.AppImage
chmod a+x linuxdeploy-x86_64.AppImage
wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/1-alpha-20240109-1/linuxdeploy-plugin-qt-x86_64.AppImage
chmod a+x linuxdeploy-plugin-qt-x86_64.AppImage

# build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$QT_DIR" -DCMAKE_INSTALL_PREFIX=
cmake --build . --parallel
make install DESTDIR="$(pwd)/AppDir"
cd AppDir || exit

# move files so that the AppDir structure is correct
mkdir usr
mv bin usr
mv lib usr
mv plugins usr
mv translations usr
cd ..

if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    echo "WSL detected, removing /mnt/c/ from PATH"
    OLD_PATH=$PATH
    PATH=$(echo "$PATH" | tr ':' '\n' | awk '($0!~/mnt\/c/) {print} ' | tr '\n' ':')
    export PATH
fi
./linuxdeploy-x86_64.AppImage --desktop-file "$CFGEditorDir/CFGEditorPlusPlus.desktop" --appdir "$(pwd)/AppDir" --plugin qt --output appimage -i "$CFGEditorDir/VioletEgg.png"
export PATH=$OLD_PATH