
# 定义VGA的宽度和高度
width = 200
height = 150

# 定义每个像素的字节长度
byte_length = 1

# 定义每个像素的颜色值，用8位二进制表示
# 前三位是video_red，中间三位是video_green，末三位是video_blue
red = 0b11100000
green = 0b00011100
blue = 0b00000011
yellow = 0b11111100

# 创建一个空的字节数组，用于存储图片的数据
data = bytearray()

# 用双重循环遍历每个像素
for y in range(height):
    for x in range(width):
        # 根据x和y的位置，决定像素的颜色
        if x < width // 2 and y < height // 2:
            # 如果x和y都小于宽度和高度的一半，像素的颜色是红色
            color = red
        elif x >= width // 2 and y < height // 2:
            # 如果x大于等于宽度的一半，而y小于高度的一半，像素的颜色是绿色
            color = green
        elif x < width // 2 and y >= height // 2:
            # 如果x小于宽度的一半，而y大于等于高度的一半，像素的颜色是蓝色
            color = blue
        else:
            # 如果x和y都大于等于宽度和高度的一半，像素的颜色是黄色
            color = yellow
        # 将像素的颜色值添加到字节数组中
        data.append(color)

# 打开一个二进制文件，用于写入图片的数据
with open('image.bin', 'wb') as f:
    f.write(data)

# # 用pickle模块将字节数组转换为二进制数据，并写入文件中
# pickle.dump(data, file)
