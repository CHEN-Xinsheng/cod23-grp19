# 导入所需的库
import numpy as np
from PIL import Image

# 定义VGA格式的像素大小
width = 200
height = 150

# 打开RGB图片文件
img = Image.open("00.png")
img = img.convert('RGB')
img = img.resize((width, height))

# # 获取图片的宽度和高度（以像素为单位）
# width, height = img.size

# 创建一个空白的VGA图片对象
vga_img = np.zeros((height, width, 3), dtype=np.uint8)

# 遍历RGB图片中的每个像素
for x in range(width):
    for y in range(height):
        # 获取当前像素的红、、绿、、蓝值（以字节为单位）
        r, g, b = img.getpixel((x, y))
        # 将红、、绿、、蓝值压缩到一个字节像素中，前三位为video_red，中间三位为video_green，末三位为video_blue
        vga_img[y, x] = (r >> 16) | (g >> 8) | b
        print((r >> 16) | (g >> 8) | b)

# 将VGA图片保存为二进制文件
vga_img.tofile("test.bin")
