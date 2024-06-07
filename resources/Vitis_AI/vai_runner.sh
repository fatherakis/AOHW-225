#!/bin/bash

# RUN THIS THROUGH DOCKER - VITIS-AI

python mobilenet_fashion_model.py --data_dir dataset/cifar10 --model_dir ./ --batch_size 64 --target DPUCVDX8G_ISA3_C32B6 --quant_mode calib
sleep 5
python mobilenet_fashion_model.py --data_dir dataset/cifar10 --model_dir ./ --batch_size 64 --target DPUCVDX8G_ISA3_C32B6 --quant_mode test --deploy


source /workspace/board_setup/VCK190/host_cross_compiler_setup.sh

unset LD_LIBRARY_PATH
source /home/vitis-ai-user/petalinux_sdk_2022.2/environment-setup-cortexa72-cortexa53-xilinx-linux

vai_c_xir -x quantize_result/MobileNetV2_int.xmodel -a /opt/vitis_ai/compiler/arch/DPUCVDX8G/VCK190/arch.json -o exports/ -n mobilenetCIFAR

mv quantize_result/ exports/quantize_result/