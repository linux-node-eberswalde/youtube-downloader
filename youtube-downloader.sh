#!/bin/bash

echo "Please follow the instructions inside this script first. You will find those inside double angle brackets, i.e. '<<' and '>>'."
exit 1 # <<remove or comment this line to enable the script>>

echo
rm -v ytdlreread ytdlstop watch*

while [ ! -f ytdlstop ]; do

  NODLS=1
  for ITEM in `cat <<add your firefox bookmark storage here, e.g. '/home/$USER/.mozilla/firefox/<strangely named folder>/bookmarkbackups/bookmarks-*.json' and check the internal syntax whether tags e.g. 'title' and 'uri' which are used in the following apply>> | sed -re "s/.title.:/\n&/g" | grep "YTDL:" | sed -re "s/.title.:.YTDL:([^\"]+).,.*,.uri.:.([^\"]+).*/\1|\2/g" | sort | uniq`; do

    if [ -f ytdlreread ]; then rm ytdlreread; break; fi
    if [ -f ytdlstop   ]; then                break; fi

    echo
    echo "$ITEM"

    if [ 0 -lt `grep -c "$ITEM" ytdldone.db 2>/dev/null` ]; then
      echo "$ITEM already downloaded, skipping it..."
      continue
    fi

    echo
    NODLS=0
    wget --no-check-certificate `echo $ITEM | cut -d\| -f2`

    if [ 0 -lt `grep -c "url_encoded_fmt_stream_map" watch*` ]; then
      echo
      cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.url_encoded_fmt_stream_map.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "type=video...mp4" | grep -v "quality=small"

      echo
      cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.url_encoded_fmt_stream_map.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "type=video...mp4" | sed -re "s/.u0026/\n/g"

      URI_ENC=`cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.url_encoded_fmt_stream_map.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "type=video...mp4" | grep "quality=hd720" | sed -re "s/.u0026/\n/g" | grep "url=" | cut -d= -f2-`

      if [ -z "$URI_ENC" ]; then
        echo
        echo "No HD quality available, trying medium quality..."
        URI_ENC=`cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.url_encoded_fmt_stream_map.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "type=video...mp4" | grep "quality=medium" | sed -re "s/.u0026/\n/g" | grep "url=" | cut -d= -f2-`
      fi
    elif [ 0 -lt `grep -c "adaptive_fmts" watch*` ]; then
      echo
      cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.adaptive_fmts.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep -v "quality=small"

      echo
      cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.adaptive_fmts.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "quality=hd720" | sed -re "s/.u0026/\n/g"

      URI_ENC=`cat watch* | grep "<script>.*mp4" | sed -re "s/.*(.adaptive_fmts.: ?.)([^\"]+.).*/\1\n\2/g" | tr "," "\n" | grep "quality=hd720" | sed -re "s/.u0026/\n/g" | grep "url=" | cut -d= -f2-`
    fi

    echo
    if [ -z "$URI_ENC" ]; then
      echo "Unable to extract video URI!"
      continue
    fi

    echo "$URI_ENC"

    echo
    URI_DEC=`perl -e "use URI::Escape;\\\$uri=uri_unescape(uri_unescape(\"$URI_ENC\"));print \"\\\$uri\";"`
    echo "$URI_DEC"

    echo
    rm -v watch*

    echo
    wget --no-check-certificate -c -O "`echo $ITEM | cut -d\| -f1`" $URI_DEC

    echo "$ITEM" >> ytdldone.db
 
  done

  if [ 1 -eq $NODLS ]; then break; fi
done

if [ -f ytdlstop ]; then rm ytdlstop; fi

