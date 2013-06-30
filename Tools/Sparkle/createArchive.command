#!/bin/sh

wrkFolder="/tmp/$(uuidgen)"

buildFolder="$wrkFolder/Release"
archiveFolder="./Archives"

appBundleName=$"ARD Inspector.app"
archiveName="ARD_Inspector.app.tar.gz"
symName="ARD Inspector.app.dSYM"
releaseNoteName="ReleaseNotes.html"

codeSignIdentity="Developer ID Application: Yoann GINI"
signScript="./Tools/Sparkle/sign_update.rb"
dsaPrivateKeyPath="./Tools/Sparkle/dsa_priv.pem"

archiveSignature=""
lastCommitHash=""

intermediateAppBundlePath="$buildFolder/$appBundleName"
intermediateArchivePath="$buildFolder/$archiveName"
intermediateSYMPath="$buildFolder/$symName"

finalArchivePath="$archiveFolder/$archiveName"
finalSYMPath="$archiveFolder/$symName"

baseGITArchiveURL="https://github.com/ygini/ARD-Inspector/blob/GIT_COMMIT_VERSION/Archives/$archiveName?raw=true"
baseGITReleaseNoteURL="https://github.com/ygini/ARD-Inspector/blob/GIT_COMMIT_VERSION/Archives/$releaseNoteName?raw=true"

finalGITArchiveURL=""
finalGITReleaseNoteURL=""
humanVersion=""
buildVersion=""
updateTitle=""
pubDate=""
archiveSize=""

originalAppcastSeed="./Tools/Sparkle/appcast_seed.xml"
intermediateAppcastSeed="$wrkFolder/seed.xml"
intermediateAppcast="$wrkFolder/appcast.xml"
finalAppcast="$archiveFolder/appcast.xml"

cd "$( dirname "${BASH_SOURCE[0]}" )"
cd $(git rev-parse --show-cdup)


mkdir "$wrkFolder"
chown :staff "$wrkFolder"

xcodebuild -project "ARD Inspector.xcodeproj" -target "ARD Inspector" -configuration "Release" -sign="Yoann Gini" OBJROOT="$wrkFolder" SYMROOT="$wrkFolder"

codesign -s "$codeSignIdentity" "$intermediateAppBundlePath/Contents/Frameworks/Sparkle.framework"
codesign -s "$codeSignIdentity" "$intermediateAppBundlePath"

cd "$buildFolder"

tar czf "$archiveName" "$appBundleName"

cd -

mv "$intermediateArchivePath" "$archiveFolder"
mv "$intermediateSYMPath" "$archiveFolder"

archiveSignature=$("$signScript" "$finalArchivePath" "$dsaPrivateKeyPath" | tr -d '\n')

humanVersion="$(defaults read "$intermediateAppBundlePath/Contents/Info" CFBundleShortVersionString)"
buildVersion="$(defaults read "$intermediateAppBundlePath/Contents/Info" CFBundleVersion)"

updateTitle="$(echo "Version $humanVersion ($buildVersion)")"

pubDate="$(date +"%a, %d %b %Y %H:%M:%S %z")"

archiveSize="$(wc -c < "$finalArchivePath")"

git add "$finalArchivePath" "$finalSYMPath" "$archiveFolder/$releaseNoteName"
git commit -m "Automatic build system ($updateTitle)"

lastCommitHash="$(git rev-parse HEAD)"

finalGITArchiveURL=$(echo $baseGITArchiveURL | sed -e "s/GIT_COMMIT_VERSION/$lastCommitHash/")
finalGITReleaseNoteURL=$(echo $baseGITReleaseNoteURL | sed -e"s/GIT_COMMIT_VERSION/$lastCommitHash/")

sed -e "s#TAG_TITLE#$updateTitle#g" -e "s#TAG_RELEASE_NOTES#$finalGITReleaseNoteURL#g" -e "s#TAG_DATE#$pubDate#g" -e "s#TAG_ARCHIVE_URL#$finalGITArchiveURL#g" -e "s#TAG_SIZE#$archiveSize#g" -e "s#TAG_SIGNATURE#$archiveSignature#g" -e "s#TAG_HUMAN_VERSION#$humanVersion#g" -e "s#TAG_BUILD_VERSION#$buildVersion#g" "$originalAppcastSeed" > "$intermediateAppcastSeed"

sed -i -e "/<!-- INSERT NEXT RELEASE HERE -->/r $intermediateAppcastSeed" "$finalAppcast"

git add "$finalAppcast" "ARD Inspector/Supporting Files/ARD Inspector-Info.plist" 
git commit -m "Update appcast file and Info.plist ($updateTitle)"

rm -rf "$wrkFolder"
