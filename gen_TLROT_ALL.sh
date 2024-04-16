#!/bin/bash

# filelist 文件路径
filelist="fpga_filelist"

# 输出文件路径
output_file="TLROT_ALL.sv"

# 确保filelist文件存在
if [ ! -f "$filelist" ]; then
    echo "Filelist '$filelist' not found."
    exit 1
fi

# 清空当前输出文件（如果已存在）
> "$output_file"

while IFS= read -r line
do
    # 使用eval命令来解析行中的环境变量
    file=$(eval echo "$line")

    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "Warning: File not found -> $file"
        continue
    fi

    # 将文件内容追加到输出文件
    cat "$file" >> "$output_file"
    echo -e "\n" >> "$output_file"  # 在每个文件内容之后添加空行以防止合并上的问题
done < "$filelist"

echo "All files have been combined into $output_file."