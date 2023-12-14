# 导入PIL库，用于处理图像
from PIL import Image
from argparse import ArgumentParser

parser = ArgumentParser(description='Convert PNG to VGA')
parser.add_argument('-i', '--image_file', help='Input PNG file', type=str)
parser.add_argument('--width', help='VGA width', type=int, default=200)
parser.add_argument('--height', help='VGA height', type=int, default=150)
args = parser.parse_args()

# 定义VGA的宽度和高度
width = args.width
height = args.height

# 定义每个像素的字节长度
byte_length = 1

# 定义每个像素的颜色值，用8位二进制表示
# 前三位是video_red，中间三位是video_green，末三位是video_blue
red = 0b11100000
green = 0b00011100
blue = 0b00000011

# 打开PNG或JPG图片，并转换为RGB模式
img = Image.open(args.image_file)
img = img.convert('RGB')
img = img.resize((width, height))
img.save("test.png")

# 获取图片的宽度和高度，并计算每行和每列需要存存储多少字节
byte_per_row = width // byte_length # 每行需要存存储width / byte_length个字节
byte_per_col = height // byte_length # 每列需要存存储height / byte_length个字节

# 创建一个空的字节数组，用于存存储图片的数据
data = bytes()
# print(img.size)

# 遍历每行和每列，将RGB值转换为二进制数据，并添加到字节数组中
for i in range(byte_per_row):
    for j in range(byte_per_col):
        # 将RGB值转换为二进制数据，并添加到字节数组中
        r, g, b = img.getpixel((i, j))
        # num = int(bin((pixel[0] & 0b11100000) | ((pixel[1] & 0b11100000) >> 3) | ((pixel[2] & 0b11000000) >> 6)), 2)
        num = (r >> 16) | (g >> 8) | b

        # print(num)
        # hex_str = format(num, '02x') # format(127, '02x') = 'FF'
        # byte = ord(hex_str) # ord('FF') = 255
        byte = int.to_bytes(num, byteorder='big', length=byte_length)
        data += byte
        # print(data)
        # data.append(byte)
        
with open(f'{args.image_file.split("/")[-1].split(".")[0]}.bin', 'wb') as f:
    f.write(data)

# # 打开一个二进制文件，用于写入图片的数据
# file = open('image.bin', 'wb')

# # 将字节数组转换为二进制数据，并写入文件中
# file.write(data)

# # 关闭文件
# file.close()
