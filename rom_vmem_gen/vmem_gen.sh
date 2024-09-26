#!/bin/bash

# 检查是否提供了两个参数（elf 和 vmem 文件）
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <elf_file> <output_vmem_file>"
    exit 1
fi

# 固定的 hjson 文件路径
HJSON_FILE="./data/top_earlgrey.gen.hjson"

# 传递的 elf 和 vmem 文件参数
ELF_FILE=$1
VMEM_FILE=$2

# 运行 scramble_image.py 脚本
./src/scramble_image.py $HJSON_FILE $ELF_FILE $VMEM_FILE

# 判断脚本是否成功运行
if [ $? -eq 0 ]; then
    echo "VMEM file generated successfully: $VMEM_FILE"
else
    echo "Error: Failed to generate VMEM file"
    exit 1
fi