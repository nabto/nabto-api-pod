#!/bin/bash

set -e

SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FRAMEWORK_NAME=nabto_client_api.xcframework
ARCHIVE_BASENAME=nabto_client_api

ROOT=nabto
LICENSE=
IOS_PHONE_ARM64_DIR=iphoneos-arm64
IOS_SIM_X64_DIR=iphonesimulator-x86_64
IOS_SIM_ARM64_DIR=iphonesimulator-arm64
IOS_SIM_LIPO_DIR=iphonesimulator-lipo

LIBRARY_FILENAME=nabto_client_api

JENKINS_HEADER_DIR=$IOS_PHONE_ARM64_DIR/include
JENKINS_HEADER_FILE=$JENKINS_HEADER_DIR/nabto_client_api.h

FRAMEWORK_PATH=${ARCHIVE_BASENAME}.framework

JENKINS_FRAMEWORK_PATH=framework/$FRAMEWORK_PATH
JENKINS_IOS_PHONE_ARM64_FRAMEWORK=${IOS_PHONE_ARM64_DIR}/${JENKINS_FRAMEWORK_PATH}
JENKINS_IOS_SIM_ARM64_FRAMEWORK=${IOS_SIM_ARM64_DIR}/${JENKINS_FRAMEWORK_PATH}
JENKINS_IOS_SIM_X64_FRAMEWORK=${IOS_SIM_X64_DIR}/${JENKINS_FRAMEWORK_PATH}

IOS_PHONE_ARM64_FRAMEWORK=${IOS_PHONE_ARM64_DIR}/${FRAMEWORK_PATH}
IOS_SIM_ARM64_FRAMEWORK=${IOS_SIM_ARM64_DIR}/${FRAMEWORK_PATH}
IOS_SIM_X64_FRAMEWORK=${IOS_SIM_X64_DIR}/${FRAMEWORK_PATH}
IOS_SIM_LIPO_FRAMEWORK=${IOS_SIM_LIPO_DIR}/${FRAMEWORK_PATH}

function usage {
    echo "$0 <dir with artifacts> <output dir>"
    echo ""
    echo "Artifacts dir should have the following structure (as downloaded using 'all files in zip' from in Jenkins' artifacts/nabto dir):"
    echo ""
    echo "  artifacts_dir/"
    echo "  ├── nabto"
    echo "  │   ├── iphoneos-arm64"
    echo "  │   │   ├── framework"
    echo "  │   │   │   └── nabto_client_api.framework"  # JENKINS_IOS_PHONE_ARM64_FRAMEWORK
    echo "  │   │   │       ├── Info.plist"
    echo "  │   │   │       └── nabto_client_api"
    echo "  │   │   ├── include"
    echo "  │   │   │   └── nabto_client_api.h"
    echo "  ..."
    echo "  │   ├── iphonesimulator-arm64"
    echo "  │   │   ├── framework"
    echo "  │   │   │   └── nabto_client_api.framework"
    echo "  │   │   │       ├── Info.plist"
    echo "  │   │   │       └── nabto_client_api"
    echo "  ..."
    echo "  │   └── iphonesimulator-x86_64"
    echo "  │       ├── framework"
    echo "  │       │   └── nabto_client_api.framework"
    echo "  │       │       ├── Info.plist"
    echo "  │       │       └── nabto_client_api"
    echo "  ..."
    echo ""
    echo "The output of the script is an XCFramework bundle with the following structure: "
    echo "     nabto_client_api.xcframework"
    echo "      ├── LICENSE.txt"
    echo "      ├── iphoneos-arm64"
    echo "         nabto_client_api.framework/"
    echo "         ├── Headers"
    echo "         │   └── nabto_client_api.h"
    echo "         ├── Info.plist"
    echo "         └── nabto_client_api"
    echo "      ├── iphonesimulator-lipo"
    echo "         nabto_client_api.framework/"
    echo "         ├── Headers"
    echo "         │   └── nabto_client_api.h"
    echo "         ├── Info.plist"
    echo "         └── nabto_client_api"
    echo ""
}

function checkArtifacts() {
    dir=$1/$ROOT
    if [[ -d $dir/$JENKINS_IOS_PHONE_ARM64_FRAMEWORK &&
              -d $dir/$JENKINS_IOS_SIM_X64_FRAMEWORK &&
              -d $dir/$JENKINS_IOS_SIM_ARM64_FRAMEWORK &&
              -f $dir/$JENKINS_HEADER_FILE ]]; then
        return 0;
    else
        echo "ERROR: Unexpected structure of artifacts dir";
        exit 1
    fi
}

function restructureFrameworks {

    # copy from artifacts dir into this structure which is used as input for xcodebuild:
    #
    # tmp_restructured/
    # ├── iphoneos-arm64
    # │   │   └── nabto_client_api.framework
    # │   │       ├── Info.plist
    # │   │       └── nabto_client_api
    # │           ├── Headers
    #                    └── nabto_client_api.h
    # ├── iphonesimulator-lipo
    # │   │   └── nabto_client_api.framework
    # │   │       ├── Info.plist
    # │   │       └── nabto_client_api
    # │           ├── Headers
    #                   └── nabto_client_api.h
    #

    inputDir=`pwd`/$1/$ROOT
    tmp=$2
#    tmp=/tmp/tmp_restructured
#    rm -rf $tmp

    # iphone
    iphoneTargetDir=$tmp/$IOS_PHONE_ARM64_DIR
    mkdir -p $iphoneTargetDir
    cp -R $inputDir/$JENKINS_IOS_PHONE_ARM64_FRAMEWORK $iphoneTargetDir

    iphoneHeadersDir=$tmp/$IOS_PHONE_ARM64_FRAMEWORK/Headers
    mkdir $iphoneHeadersDir
    cp $inputDir/$JENKINS_HEADER_FILE $iphoneHeadersDir

    # create lipo version of sim architectures
    simTargetDir=$tmp/$IOS_SIM_LIPO_FRAMEWORK
    mkdir -p $simTargetDir
    lipo -create \
         $inputDir/$JENKINS_IOS_SIM_ARM64_FRAMEWORK/$LIBRARY_FILENAME \
         $inputDir/$JENKINS_IOS_SIM_X64_FRAMEWORK/$LIBRARY_FILENAME \
         -output $simTargetDir/$LIBRARY_FILENAME

    # copy Info.plist from arm64 sim slice
    cp $inputDir/$JENKINS_IOS_SIM_ARM64_FRAMEWORK/Info.plist $simTargetDir

    # copy headers from iOS
    simHeadersDir=$simTargetDir/Headers
    mkdir $simHeadersDir
    cp -R $inputDir/$JENKINS_HEADER_FILE $simHeadersDir

    echo "New structure:"
    tree $tmp
}

function createBundle() {
    inputDir=$1
    outputDir=$2
    rm -rf $outputDir/$FRAMEWORK_NAME
    cd $inputDir

    echo "Creating bundle in this tree:"
    pwd
    tree

    xcodebuild -create-xcframework \
               -framework $IOS_PHONE_ARM64_FRAMEWORK  \
               -framework $IOS_SIM_LIPO_FRAMEWORK     \
               -output $outputDir/$FRAMEWORK_NAME
    cp $SCRIPT_DIR/LICENSE.txt $outputDir/$FRAMEWORK_NAME
    cd $outputDir
    zip -r $FRAMEWORK_NAME.zip $FRAMEWORK_NAME
}

function main() {
    if [[ $# != 2 || ! -d $1 ]]; then
        usage
        exit 1
    fi

    tmp=`mktemp -d`

    checkArtifacts $1
    restructureFrameworks $1 $tmp
    createBundle $tmp $2

#    rm -rf $tmp
}

main $*
