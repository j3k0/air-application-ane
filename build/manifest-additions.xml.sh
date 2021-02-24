#!/bin/bash

cd "$(dirname "$0")"

if [ ! -e "temp/android" ]; then
  ant android
fi

# Permissions
function usesPermissionsRaw() {
  echo '<manifest>'
    for i in ../android/manifest-additions.xml temp/android/*-AndroidManifest.xml; do
      cat $i | xq --xml-root=uses-permission --xml-output '.manifest["uses-permission"]'
      cat $i | xq --xml-root=uses-feature --xml-output '.manifest["uses-feature"]'
    done \
      | grep -v '^<uses-permission></uses-permission>$' \
      | grep -v '^<uses-feature></uses-feature>$'
  echo '<uses-permission android:name="android.permission.CAMERA"/>'
  echo '</manifest>'
}

function usesPermissions() {
  usesPermissionsRaw \
    | xmllint --format - 2>/dev/null \
    | grep -E 'uses-permission|uses-feature' \
    | sort | uniq
}

function appComponentFactory() {
  for i in temp/android/*-AndroidManifest.xml; do
    cat $i | xq '.manifest.application["@android:appComponentFactory"]'
  done \
    | grep -v '^null$'
}

function application() {
  # android:appComponentFactory
  echo '<application
    android:appComponentFactory='$(appComponentFactory)'
  >'

  for i in ../android/manifest-additions.xml temp/android/*-AndroidManifest.xml; do
    # Services
    cat $i | xq --xml-root=service --xml-output '.manifest.application.service'
    # Receivers
    cat $i | xq --xml-root=receiver --xml-output '.manifest.application.receiver'
    # Providers
    cat $i | xq --xml-root=provider --xml-output '.manifest.application.provider'
    # Activities
    cat $i | xq --xml-root=activity --xml-output '.manifest.application.activity'
    # Meta-datas
    cat $i | xq --xml-root=meta-data --xml-output '.manifest.application["meta-data"]'
  done \
    | grep -v '^<service></service>$' \
    | grep -v '^<receiver></receiver>$' \
    | grep -v '^<meta-data></meta-data>$' \
    | grep -v '^<activity></activity>$' \
    | grep -v '^<provider></provider>$' \
    | sed 's/ tools:[a-zA-Z]*="[a-zA-Z:]*"/ /g'

  echo '</application>'
}

(
  echo '<manifest
    android:installLocation="auto"
  >'
  usesPermissions
  application
  echo '</manifest>'
) \
  | xmllint --format - 2>/dev/null \
  | sed 's/${applicationId}/air.nl.goliathgames.triominos/g' \
  | grep -v '<?xml' \
  | tee manifest-additions.xml.in

echo 'IMPORTANT: Some manual work for you.'
echo
echo 'The file has been generated as manifest-additions.xml.in'
echo
echo 'In this file, there should be multiple entries for the ComponentDiscoveryService:'
echo
echo '<service android:name="com.google.firebase.components.ComponentDiscoveryService" ...>'
echo
echo 'You have to merge them manually: copy all meta-data childs and all attributes to a single entry. The result should look like this:'
echo
cat << EOF
    <service android:name="com.google.firebase.components.ComponentDiscoveryService" android:directBootAware="true" android:exported="false">
      <meta-data android:name="com.google.firebase.components:com.google.firebase.crash.component.FirebaseCrashRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.auth.FirebaseAuthRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.datatransport.TransportRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.iid.Registrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.installations.FirebaseInstallationsRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.messaging.FirebaseMessagingRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
      <meta-data android:name="com.google.firebase.components:com.google.firebase.analytics.connector.internal.AnalyticsConnectorRegistrar" android:value="com.google.firebase.components.ComponentRegistrar"/>
    </service>
EOF
echo 'Save the resulting file as manifest-additions.xml'
