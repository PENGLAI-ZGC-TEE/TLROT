import re
import os
import sys

# 定义前缀
prefix = "bosc_"

# 定义匹配正则表达式
module_pattern = re.compile(r"^(?!//)\s*\b(module|package)\s+(\w+)\b", re.MULTILINE)  # 匹配module或package定义，忽略注释行
instance_pattern = re.compile(r"\b(\w+)\s+(#\s*\([^)]*\)\s*)?(\w+)\b")  # 匹配模块实例化，包括带参数和不带参数的实例化
simple_module_name_pattern = re.compile(r"\b(\w+)\b")  # 捕获模块名和包名，不包含参数或实例化名称
package_import_pattern = re.compile(r"\b(\w+_pkg)\b::\*")
package_dot_pattern = re.compile(r"\b(\w+_pkg)\.")  # 匹配 package_name. 的调用形式
end_module_pattern = re.compile(r"^(?!//)\s*\b(endmodule|endpackage)\s*:\s*(\w+)\b", re.MULTILINE)  # 忽略注释行中的endmodule/endpackage
package_double_colon_pattern = re.compile(r"\b(\w+_pkg)::(\w+)\b")  # 匹配 package::member 格式
comment_pattern = re.compile(r"//.*")  # 匹配注释行

# 关键字排除列表，防止误修改
exclude_keywords = {"parameter", "int", "is", "in", "to", "prevent", "warnings", "the", "package"}

# 初始化模块和包名列表
module_package_names = set()

def collect_module_package_names(content):
    # 收集所有module和package的名称
    for match in module_pattern.finditer(content):
        module_package_names.add(match.group(2))

def modify_content(content, prefix):
    # 提取并排除注释
    comments = comment_pattern.findall(content)
    code_only = comment_pattern.sub("", content)  # 去掉注释内容只处理代码部分

    # 修改module和package的定义，包括package <name>;
    def replace_module_package(match):
        if match.group(1) == "package" and match.group(2) in module_package_names:
            return f"{match.group(1)} {prefix}{match.group(2)}"
        elif match.group(1) == "module":
            return f"{match.group(1)} {prefix}{match.group(2)}"
        return match.group(0)

    # 修改模块实例化的模块名，但保留实例化标识符
    def replace_instance_name(match):
        module_name = match.group(1)
        params = match.group(2) if match.group(2) else ""
        instance_name = match.group(3)

        if module_name in module_package_names:
            return f"{prefix}{module_name} {params}{instance_name}"
        return match.group(0)

    # 修改模块或包名称中的模块名
    def replace_module_name(match):
        module_name = match.group(1)
        if module_name in module_package_names and module_name not in exclude_keywords:
            next_chars = code_only[match.end():match.end() + 2]
            if next_chars.startswith("#(") or next_chars.startswith(" "):
                return f"{prefix}{module_name}"
        return module_name

    # 修改 package::* 调用
    def replace_package_import(match):
        package_name = match.group(1)
        if package_name in module_package_names:
            return f"{prefix}{package_name}::*"
        return match.group(0)

    # 修改 package::member 格式，分别检查package和member是否在模块列表中
    def replace_package_double_colon(match):
        package_name = match.group(1)
        member_name = match.group(2)
        package_name_with_prefix = f"{prefix}{package_name}" if package_name in module_package_names else package_name
        member_name_with_prefix = f"{prefix}{member_name}" if member_name in module_package_names else member_name
        return f"{package_name_with_prefix}::{member_name_with_prefix}"

    # 修改 package. 调用格式
    def replace_package_dot(match):
        package_name = match.group(1)
        if package_name in module_package_names:
            return f"{prefix}{package_name}."
        return match.group(0)

    # 修改endmodule和endpackage的名称
    def replace_end_module_package(match):
        end_type = match.group(1)
        name = match.group(2)
        if name in module_package_names:
            return f"{end_type} : {prefix}{name}"
        return match.group(0)

    # 应用各类替换操作到代码部分
    code_only = module_pattern.sub(replace_module_package, code_only)
    code_only = instance_pattern.sub(replace_instance_name, code_only)
    code_only = simple_module_name_pattern.sub(replace_module_name, code_only)
    code_only = package_import_pattern.sub(replace_package_import, code_only)
    code_only = package_double_colon_pattern.sub(replace_package_double_colon, code_only)
    code_only = package_dot_pattern.sub(replace_package_dot, code_only)
    code_only = end_module_pattern.sub(replace_end_module_package, code_only)

    # 重新组合注释和代码
    for comment in comments:
        code_only += f"\n{comment}"
    
    return code_only

def process_files(directory, prefix):
    # 第一次遍历：收集module和package名称
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".sv"):
                file_path = os.path.join(root, file)
                with open(file_path, "r") as f:
                    content = f.read()
                collect_module_package_names(content)

    # 第二次遍历：修改文件内容直接写回原文件
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".sv"):
                file_path = os.path.join(root, file)
                
                # 读取和修改文件内容
                with open(file_path, "r") as f:
                    content = f.read()
                
                new_content = modify_content(content, prefix)
                
                # 将修改后的内容写回原文件
                with open(file_path, "w") as f:
                    f.write(new_content)
                
                print(f"Processed file: {file_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <directory_path>")
        sys.exit(1)

    # 从命令行获取路径
    directory_path = sys.argv[1]
    process_files(directory_path, prefix)