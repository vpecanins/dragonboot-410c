#!/bin/bash
# http://releases.linaro.org/96boards/dragonboard410c/linaro/debian/18.01/

set -e

echo_info () {
	echo -e "\e[1m\e[92m$1\e[0m"
}

if [ ! -d "arm-eabi-4.8" ]; then
	echo_info "GIT clone arm-eabi-4.8..."
	git clone git://codeaurora.org/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8.git -b LA.BR.1.1.3.c4-01000-8x16.0
fi

if [ ! -d "lk" ]; then
	echo_info "GIT clone lk..."
	git clone http://git.linaro.org/landing-teams/working/qualcomm/lk.git -b dragonboard410c-LA.BR.1.2.7-03810-8x16.0-linaro2
fi

if [ ! -d "signlk" ]; then
	echo_info "GIT clone signlk..."
	git clone https://git.linaro.org/landing-teams/working/qualcomm/signlk.git
fi

echo_info "Build LK..."
cd lk
make -j4 -B all

echo_info "Sign LK..."
cp ./build-msm8916/lk_stripped.elf ./build-msm8916/emmc_appsboot_unsigned.mbn
../signlk/signlk.sh -i=./build-msm8916/emmc_appsboot_unsigned.mbn -o=./build-msm8916/emmc_appsboot.mbn -d


echo_info "Fastboot..."
sudo fastboot flash aboot ./build-msm8916/emmc_appsboot.mbn
cd ..

sudo fastboot reboot

