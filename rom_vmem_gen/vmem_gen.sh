#!/bin/bash

# 检查是否提供了至少两个参数（elf 和 vmem 文件）
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <elf_file> <output_vmem_file> [data_width (32 or 64)]"
    exit 1
fi

# 固定的 hjson 文件路径
HJSON_FILE="./data/top_earlgrey.gen.hjson"

# 传递的 elf 和 vmem 文件参数
ELF_FILE=$1
VMEM_FILE=$2

# 可选的数据宽度参数，默认是32
DATA_WIDTH=${3:-32}

# 检查数据宽度是否为32或64
if [ "$DATA_WIDTH" -ne 32 ] && [ "$DATA_WIDTH" -ne 64 ]; then
    echo "Error: Data width must be 32 or 64"
    exit 1
fi

# 运行 scramble_image.py 脚本并传递数据宽度
./src/scramble_image.py $HJSON_FILE $ELF_FILE $VMEM_FILE $DATA_WIDTH

# ./script.sh input.elf output.vmem 64

# 判断脚本是否成功运行
if [ $? -eq 0 ]; then
    echo "VMEM file generated successfully: $VMEM_FILE with data width $DATA_WIDTH"
else
    echo "Error: Failed to generate VMEM file"
    exit 1
fi