#!/bin/bash

ERR_PLIST_FILE_NOT_FOUND=1
ERR_BUILD_CONF_NOT_FOUND=2
ERR_PROJECT_FILE_NOT_FOUND=3
ERR_XCODE_PROJECT_FILE_NOT_FOUND=4
ERR_XCODE_ARCHIVE_FAILED=5
ERR_IPA_GENERATE_FAILED=6
ERR_VERSION_NAME_NOT_FOUND=7
ERR_CODE_NOT_FOUND=8
ERR_PROJECT_PATH_NOT_FOUND=9
ERR_BRANCH_PARAMETER_EMPTY=10
ERR_CONFIGURATION_MODE=11

#iOS编译配置函数
buildConfigure ()
{
    echo "==========================================="
    echo "==========BUILD CONFIGRATION BEGIN========"
    echo "==========================================="  

    #变量
    app_infoplist_path="${PROJECT_PATH}/${PROJECCT_INFO_PLIST_PATH}"

    if [ -f "${app_infoplist_path}" ]; then
        if [ -z "${projectname}" ]; then          
                #修改版本号、build号
                /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString ${VERSION_NAME}" ${app_infoplist_path}
                /usr/libexec/PlistBuddy -c "Set CFBundleVersion ${VERSION_CODE}" ${app_infoplist_path}

                #取版本号
                bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
                #取build值
                bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
                #取displayName
                displayName=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName" ${app_infoplist_path})

            cd ${PROJECT_PATH} 

            git status
            git add *
            git commit -m"Update Version Info Current Version:{$bundleShortVersion},Current Build Version:{$bundleVersion},Current APP Name:{$displayName}"

            if [ ! $? -eq 0 ]; then
                echo "[ERROR!]Local branch commit failed,Plesase check it!"
            fi
        fi
    else
        # echo "There is something wrong,Cann't found info plist"
        exit ${ERR_PLIST_FILE_NOT_FOUND}
    fi

    echo "==========================================="
    echo "==========BUILD CONFIGRATION END==========="
    echo "==========================================="
}

#iOS编译函数
build ()
{
    echo "==========================================="
    echo "==========Xcode build begin================"
    echo "==========================================="

    #参数配置
    buildProject=$1
    buildScheme=$2
    configurationMode=$3
    archivePath=$4
    projectname="${PROJECT_NAME}"
    xcodeprojectPath="${PROJECT_PATH}/${PROJECT_NAME}"

    if [ -d "${archivePath}" ]; then
        rm -rf "${archivePath}"
    fi

    if [ -d "${PROJECT_PATH}/${XCWORKSPACE}" ]; then
        if [ -d "${xcodeprojectPath}" ]; then
            cd "${xcodeprojectPath}"
            #Clean project
            xcodebuild clean -configuration "${configurationMode}"
            #Begin Build 
            if [ ! -z "${buildProject}" ] && [ ! -z "${buildScheme}" ]; then
               #xcodebuild generate *.xcarchive file
               if [ "${configurationMode}" == "Debug" ]; then 
                    xcodebuild archive -workspace "${buildProject}" -scheme "${buildScheme}" -configuration "${configurationMode}" -sdk iphoneos -archivePath "${archivePath}" ONLY_ACTIVE_ARCH=NO 
               elif [ "${configurationMode}" == "Release" ]; then
                   #statements
                   xcodebuild archive -workspace "${buildProject}" -scheme "${buildScheme}" -configuration "${configurationMode}" -sdk iphoneos -archivePath "${archivePath}" ONLY_ACTIVE_ARCH=NO build CODE_SIGN_IDENTITY="${APPSTORE_CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${APPSTORE_ROVISIONING_PROFILE_NAME}"
              fi
          fi
        fi
    elif [ -d "${PROJECT_PATH}/${XCODEPROJ_PATH}" ]; then
        if [ -d "${xcodeprojectPath}" ]; then
            cd "${xcodeprojectPath}"
            #Clean project
            xcodebuild clean -configuration "${configurationMode}"
            #Begin Build 
            if [ ! -z "${buildProject}" ] && [ ! -z "${buildScheme}" ]; then
               #xcodebuild generate *.xcarchive file
               # xcodebuild archive -workspace LCKC.xcworkspace -scheme LCKC -configuration Debug -archivePath ~/Desktop/build/LCKC.xcarchive
               if [ "${configurationMode}" == "Debug" ]; then
                    xcodebuild archive -project "${buildProject}" -scheme "${buildScheme}" -configuration "${configurationMode}" -archivePath "${archivePath}" ONLY_ACTIVE_ARCH=NO
               elif [ "${configurationMode}" == "Release" ];then
                    xcodebuild archive -project "${buildProject}" -scheme "${buildScheme}" -configuration "${configurationMode}" -archivePath "${archivePath}" ONLY_ACTIVE_ARCH=NO build CODE_SIGN_IDENTITY="${APPSTORE_CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${APPSTORE_ROVISIONING_PROFILE_NAME}"
               fi               
            fi
        fi
    else
        echo "[ERROR!]Xcode project file not found!"
        exit ${ERR_XCODE_PROJECT_FILE_NOT_FOUND}
    fi       
    echo "==========================================="
    echo "==============Xcode build end=============="
    echo "==========================================="
}

#iOS打包函数导出IPA文件
iOSPackageAndExport ()
{
    echo "==========================================="
    echo "==========Package begin===================="
    echo "==========================================="

    buildProject=$1
    archivePath=$2
    exportPackagePath=$3
    exportOptionsPlistFilePath=$4

    if [ -d "${exportPackagePath}" ]; then
        rm -rf "${exportPackagePath}"
    fi

    if [ ! -f "${exportOptionsPlistFilePath}" ]; then
        exit ${ERR_PLIST_FILE_NOT_FOUND}
    fi

    if [ ! -z "${buildProject}" ]; then
        xcodebuild -exportArchive -archivePath  "${archivePath}" -exportPath  "${exportPackagePath}" -exportOptionsPlist "${exportOptionsPlistFilePath}"
    fi
    echo "==========================================="
    echo "==========Package end======================"
    echo "==========================================="
}

while [ $# != 0 ]
    do
        case "$1"  in 
        "-n")
        shift
        VERSION_NAME=$1
        ;;

        "-c")
        shift
        VERSION_CODE=$1
        ;;

        "-m")
        shift
        CONFIGURATION_MODE=$1
        ;;

        "-p")
        shift
        PROJECT_PATH=$1
        ;;
        
        "-b")
        shift
        BRANCH_NAME=$1
        ;;
        
        esac 

        shift
done
#检查版本名称是否正确(非空)
if [ -z "${VERSION_NAME}" ];then
    exit ${ERR_VERSION_NAME_NOT_FOUND}
fi
echo "version name: ${VERSION_NAME}"

#检查版本号是否正确（非空）
if [ -z "${VERSION_CODE}" ];then
    exit ${ERR_CODE_NOT_FOUND}
fi
echo "version code: ${VERSION_CODE}"

#检查工程路径是否正确
if [ -z "${PROJECT_PATH}" ];then
    exit ${ERR_PROJECT_PATH_NOT_FOUND}
fi
echo "project_path: ${PROJECT_PATH}"

#检查branch是否为空
if [ -z "${BRANCH_NAME}" ];then
    exit ${ERR_BRANCH_PARAMETER_EMPTY}
fi

if [ "${CONFIGURATION_MODE}" == "Debug" ]; then
    buildConfigure 
    build ${buildProject} ${buildScheme} ${CONFIGURATION_MODE} ${archivePath}
    iOSPackageAndExport ${buildProject} ${archivePath} "${exportPackagePath}/${CONFIGURATION_MODE}" "${exportOptionsPlistFilePath}/DebugExportOptions.plist"
    copyToTarget ${CONFIGURATION_MODE} ${exportPackagePath}
elif [ "${CONFIGURATION_MODE}"  == "Release" ]; then
    buildConfigure
    build ${buildProject} ${buildScheme} ${CONFIGURATION_MODE} ${archivePath}
    iOSPackageAndExport ${buildProject} ${archivePath} "${exportPackagePath}/${CONFIGURATION_MODE}" "${exportOptionsPlistFilePath}/AppStoreExportOptions.plist"
    copyToTarget ${CONFIGURATION_MODE} ${exportPackagePath}
elif [ "${CONFIGURATION_MODE}" == "All" ]; then
    buildConfigure
    ipaName_Debug="${SCHEME}_CONFIGURATION_MODE_${VERSION_CODE}.ipa"
    ipaName_Release="${SCHEME}_CONFIGURATION_MODE_${VERSION_CODE}.ipa"
    #build Debug
    build ${buildProject} ${buildScheme} "Debug" ${archivePath}
    iOSPackageAndExport ${buildProject} ${archivePath} "{exportPackagePath}/Debug" "${exportOptionsPlistFilePath}/DebugExportOptions.plist"
    copyToTarget "Debug" "${exportPackagePath}/Debug"
    #build Release
    build ${buildProject} ${buildScheme} "Release" ${archivePath}
    iOSPackageAndExport ${buildProject} ${archivePath} "{exportPackagePath}/Release" "${exportOptionsPlistFilePath}/AppStoreExportOptions.plist"
    copyToTarget "Release" "${exportPackagePath}/Release"
else
    exit ${ERR_CONFIGURATION_MODE}
fi



