#!/bin/bash 

#User Input
#echo "Please enter device codename"
#read DEVICE

#Variables 
KERNELDIR="/home/madeofgreat/Development/Delta/delta_beryllium"
CCDIR="/home/madeofgreat/Development/proton-clang/aarch64-linux-gnu"
CC32DIR="/home/madeofgreat/Development/proton-clang/arm-linux-gnueabi"
CLANGDIR="/home/madeofgreat/Development/proton-clang"
LOGDIR="/home/madeofgreat/logs"
ANYKERNELDIR="/home/madeofgreat/Development/Delta/AnyKernel3"
DEVICE="beryllium"
ARCH="arm64"
SUBARCH="arm64"
LINKER="lld"
KERNELNAME="Delta"
# Choose default linker if none is specified
if [ ${LINKER} == "" ]
then
    $LINKER="bfd"
fi

# Messages
echo "    
    Building $KERNELNAME kernel for $DEVICE
    The source directory is $KERNELDIR
    The cross compiler directory is $CCDIR
    The clang directory is $CLANGDIR
    The linker chosen is ${LINKER}

    "
    
#Build
cd ${KERNELDIR}
curl -s -X POST https://api.telegram.org/bot1143909985:AAETJx6Mf-grKQxQ7UMFxC5AjzFt0JEOVhw/sendMessage -d text="$KERNELNAME kernel: Build started
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>" -d chat_id=-1001367259540 -d parse_mode=HTML

cd ${CCDIR}
export CROSS_COMPILE=$(pwd)/bin/aarch64-linux-gnu-
cd ${CC32DIR}
export CROSS_COMPILE_ARM32=$(pwd)/bin/arm-linux-gnueabi-
cd $KERNELDIR
export ARCH=${ARCH} && export SUBARCH=${SUBARCH}
make O=out ARCH=$ARCH ${DEVICE}_defconfig
if [ $? -ne 0 ]
then
    echo "  Couldn't make ${DEVICE}_defconfig"
else
    echo "  Made ${DEVICE}_defconfig"
    if [ $? -ne 0 ]
    then
        echo "Build failed"
    else
        PATH="${CLANGDIR}/bin:${CCDIR}/bin:${PATH}"\
        make LD=ld.${LINKER} -j$(nproc --all) O=out \
            ARCH=${ARCH} \
            CC=clang \
            CROSS_COMPILE=aarch64-linux-gnu- \
            CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
            ld-name=$LINKER
        if [ $? -ne 0 ]
        then
            echo "Build failed"
            curl -s -X POST https://api.telegram.org/bot1143909985:AAETJx6Mf-grKQxQ7UMFxC5AjzFt0JEOVhw/sendMessage -d text="$KERNELNAME kernel: Build throwing errors" -d chat_id=-1001367259540 -d parse_mode=HTML
        else 
            echo "Build succesful"
            mv ${KERNELDIR}/out/arch/arm64/boot/Image.gz-dtb ${ANYKERNELDIR}/
            cd ${ANYKERNELDIR}
            zip -r ${ANYKERNELDIR}/${KERNELNAME}_Kernel *
            
            curl -s -X POST https://api.telegram.org/bot1143909985:AAETJx6Mf-grKQxQ7UMFxC5AjzFt0JEOVhw/sendMessage -d text="$KERNELNAME kernel: Build succesful" -d chat_id=-1001367259540 -d parse_mode=HTML
            curl -F chat_id="-1001367259540" -F document=@"${ANYKERNELDIR}/${KERNELNAME}_Kernel.zip" https://api.telegram.org/bot"1143909985:AAETJx6Mf-grKQxQ7UMFxC5AjzFt0JEOVhw"/sendDocument
        fi
    fi
fi
