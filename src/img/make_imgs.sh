cd ../..

magick src/img/icon.png -resize 440x440 -background transparent -gravity center -extent 512x512 src/img/icon_512_padded.png

magick src/img/icon_512_padded.png -resize 128x128 static/img/icon_128.png
magick src/img/icon_512_padded.png -resize 512x512 static/img/icon_512.png

magick src/img/icon_512_padded.png -resize 48x48 \
  -define icon:auto-resize=16,32,48 static/favicon.ico
