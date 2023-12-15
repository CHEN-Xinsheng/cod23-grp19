# 导入os模块，用于操作文件和目录
import os

# 定义一个函数，接受一个文件夹路径和一个输出文件名作为参数
def merge_bin_files(folder_path, output_file):
    # 创建一个空的字节对象，用于存储合并后的二进制数据
    merged_data = b''
    # 遍历文件夹下的所有文件，按照文件名的数字顺序排序
    for file in range(0, 128):
        file = str(file)
        if len(file) == 1:
            file = '0' + file
        file = file + '.bin'
        # 拼接文件的完整路径
        file_path = os.path.join(folder_path, file)
        # 打开文件，以二进制模式读取
        with open(file_path, 'rb') as f:
            # 读取文件的所有内容，并追加到合并后的数据中
            merged_data += f.read()
    # 打开输出文件，以二进制模式写入
    with open(output_file, 'wb') as f:
        # 写入合并后的数据
        f.write(merged_data)

# 调用函数，传入文件夹路径和输出文件名
merge_bin_files('Trump_Biden', 'merged.bin')
