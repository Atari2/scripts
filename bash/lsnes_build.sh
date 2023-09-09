# dependencies I had to install:
# sudo apt install libgcrypt20-dev
# sudo apt install portaudio19-dev
# sudo apt install libwxgtk3.0-gtk3-dev
# sudo apt install libswscale-dev

# keep in mind you also need lua, boost and curl-config
# which can be installed with:
# sudo apt-get install lua5.4
# sudo apt-get install liblua5.4-dev
# sudo apt-get install libcurl4-gnutls-dev
# sudo apt-get install libboost-all-dev --fix-missing

git clone https://repo.or.cz/lsnes.git
cd lsnes/bsnes
wget https://github.com/Alcaro/bsnes-gc/raw/master/bsnes_v085-source.tar.bz2
tar -xf bsnes_v085-source.tar.bz2
rm bsnes_v085-source.tar.bz2
mv bsnes_v085-source/bsnes/* .
rm -rf bsnes_v085-source
for i in ../bsnes-patches/v085/*.patch
do
        patch -p1 < $i
done
cd ../gambatte
wget https://sourceforge.net/projects/gambatte/files/gambatte/r537/gambatte_src-r537.tar.gz/download
tar -xf download
rm download
mv gambatte_src-r537/* .
rm -rf gambatte_src-537
for i in ../libgambatte-patches/svn537/*.patch
do
        patch -p1 < $i
done
cd ..
make