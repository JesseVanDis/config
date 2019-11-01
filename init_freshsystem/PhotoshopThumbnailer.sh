#!/bin/bash

# -----------------------------------------------------------
# -- Write psdthumbnailer
# -----------------------------------------------------------
OUTFILE=/usr/lib/psdthumbnailer
(
sudo cat <<'EOF'
# bin/bash

# Arguments / Parameters %i %o %s
f_in=$1
f_out=$2
f_size=$3

# Execute Convert PSD to PNG through ImageMagick
exec convert "psd:$f_in[0]" -scale "$f_sizex$f_size" "png:$f_out"

EOF
) > $OUTFILE
# -----------------------------------------------------------
# -- Write photoshop.thumbnailer
# -----------------------------------------------------------
OUTFILE=/usr/share/thumbnailers/photoshop.thumbnailer
(
sudo cat <<'EOF'
# bin/bash
[Thumbnailer Entry]
TryExec=/usr/lib/psdthumbnailer
Exec=/usr/lib/psdthumbnailer %i %o %s
MimeType=image/vnd.adobe.photoshop; image/x-photoshop; image/x-psd;
EOF
) > $OUTFILE
# -----------------------------------------------------------
# -- Set File Permissions
# -----------------------------------------------------------
sudo chmod 0755 /usr/lib/psdthumbnailer
sudo chmod 0644 /usr/share/thumbnailers/photoshop.thumbnailer

# -----------------------------------------------------------
# -- Add GConf Hooks to parse thumbnails
# -----------------------------------------------------------
sudo gconftool-2 --set /desktop/gnome/thumbnailers/image@vnd.adobe.photoshop/enable --type bool true

sudo gconftool-2 --set /desktop/gnome/thumbnailers/image@vnd.adobe.photoshop/command --type string "/usr/lib/psdthumbnailer %i %o %s %i %o %s"

# -----------------------------------------------------------
# -- Install Dependencies
# -----------------------------------------------------------

sudo apt-get install imagemagick
