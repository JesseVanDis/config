cd ~/.emacs.d/emacs26
wget http://mirror.netcologne.de/gnu/emacs/emacs-26.1.tar.xz
tar xvfJ ./emacs-26.1.tar.xz
cd ./emacs-26.1/
sudo apt-get update
gnutlsPackageName=$(apt-cache search 'libgnutls.*-dev' | head -n 1 | awk '{print $1}')
echo "gnuLtsPackage to be checked: ${gnutlsPackageName}"
!dpkg -s ${gnutlsPackageName} 2>/dev/null >/dev/null || sudo apt-get install ${gnutlsPackageName}
!dpkg -s libxpm-dev 2>/dev/null >/dev/null || sudo apt-get install libxpm-dev
!dpkg -s libgtk-3-dev 2>/dev/null >/dev/null || sudo apt-get install libgtk-3-dev
!dpkg -s libjpeg-dev 2>/dev/null >/dev/null || sudo apt-get install libjpeg-dev
!dpkg -s libtiff-dev 2>/dev/null >/dev/null || sudo apt-get install libtiff-dev
!dpkg -s libgif-dev 2>/dev/null >/dev/null || sudo apt-get install libgif-dev
!dpkg -s lib32ncurses5-dev 2>/dev/null >/dev/null || sudo apt-get install lib32ncurses5-dev
./configure
echo "did everything go well ? if not close the window"
echo "press [ENTER] to continue"
read sjaak
make
sudo make install
echo "done"
echo "press [ENTER] to continue"
read henk
