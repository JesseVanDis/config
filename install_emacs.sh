cd ~/.emacs.d/emacs26
wget http://mirror.netcologne.de/gnu/emacs/emacs-26.1.tar.xz
tar xvfJ ./emacs-26.1.tar.xz
cd ./emacs-26.1/
!dpkg -s libjpeg-dev 2>/dev/null >/dev/null || sudo apt-get install libjpeg-dev
!dpkg -s libtiff-dev 2>/dev/null >/dev/null || sudo apt-get install libtiff-dev
!dpkg -s libgif-dev 2>/dev/null >/dev/null || sudo apt-get install libgif-dev
./configure
echo "did everything go well ? if not close the window"
echo "press [ENTER] to continue"
read sjaak
make
sudo make install
echo "done"
echo "press [ENTER] to continue"
read henk
