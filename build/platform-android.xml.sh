#!/bin/bash

if test ! -e temp/android/libAneTriominos.jar
then
  ant android
fi

function filterPackage() {
  echo NO
# LOC_PACKAGE_NAME="$1"
# if echo "$PACKAGE_NAME" \
#   | grep -q -v '^androidx'  # blacklist all from androidx
# then
#   echo NO
# else
#   echo SKIP
# fi
}

function packageName() {
  LOC_BASENAME="$1"
  LOC_MANIFEST="temp/android/$LOC_BASENAME-AndroidManifest.xml"
  echo $(test -e "$LOC_MANIFEST" && cat "$LOC_MANIFEST" | xq -r '.manifest["@package"]')
}

(

echo '<platform xmlns="http://ns.adobe.com/air/extension/33.1">
    <packagedDependencies>
'
for i in $(
  ls temp/android/*.jar \
    | grep -- - \
    | sort
  )
do
  PACKAGE_NAME="$(packageName $(basename "$i" .jar))"
  if [ $(filterPackage "$PACKAGE_NAME") != "SKIP" ]
  then
    echo "        <packagedDependency>$(basename "$i")</packagedDependency>"
  fi
done
echo '
    </packagedDependencies>

    <packagedResources>
     
        <packagedResource>
            <packageName>air.nl.goliathgames.triominos</packageName>
            <folderName>res</folderName>
        </packagedResource>
    '

for i in $(
  /bin/ls -1 temp/android \
    | grep -- '-res$' \
    | sort
  )
do
  PACKAGE_NAME="$(packageName $(basename "$i" -res))"
  if [ ! -z "$PACKAGE_NAME" ] && [ "$(filterPackage "$PACKAGE_NAME")" != "SKIP" ]
  then
    FOLDER_NAME="$(basename "$i")"
    echo "        <packagedResource>
            <packageName>$PACKAGE_NAME</packageName>
            <folderName>$FOLDER_NAME</folderName>
        </packagedResource>"
  fi
done

echo '
    </packagedResources>

</platform>
'

) | tee platform-android.xml
