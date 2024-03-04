import os
import numpy as np 
from PIL import Image 

# 图片文件路径
imgs_path = 'Trump_Biden'

# 调整原图像大小可设置set_size=1,反之为=0
set_size = 1
img_w = 200 
img_h = 150

# 读取图片并做大小调整
def gen_img():
    imgs = []
    img_names = []
    for img_name in os.listdir(imgs_path):
        img_path = os.path.join(imgs_path, img_name)
        img = Image.open(img_path)
        img_name = img_name.split("/")[-1].split(".")[0]
        if set_size == 1: 
            img = img.resize((img_w, img_h))
            img.save(os.path.join(imgs_path, f"{img_name}_rescale.png"))
        img = np.array(img)
        imgs.append(img)
        img_names.append(img_name)
    return imgs, img_names

# 分别生成R G B的coe文件
def gen_coe(img, name):
    img_R = []
    img_G = []
    img_B = []
    img_A = []
    rgb = []
    print (img.shape[0])
    print (img.shape[1])
    for i in range(img.shape[0]): 
        for j in range(img.shape[1]): 
            img_R.append((img[i][j][0]>>5)<<5)
            img_G.append((img[i][j][1]>>5)<<5)
            img_B.append((img[i][j][2]>>6)<<6)
            rgb.append(((img[i][j][0]>>5)<<5)+((img[i][j][1]>>5)<<2)+(img[i][j][2]>>6))
            # img_A.append(img[i][j][3])
    print (len(img_R))
    print (len(rgb))
    with open('Picture_R_Rom.coe', 'w') as f:
        f.writelines('memory_initialization_radix = 10;\nmemory_initialization_vector = ')
        for i in range(len(img_R)): 
            if i % img.shape[1] == 0: 
                f.write('\n')
            f.write(str(img_R[i]).rjust(4) + ',')
    f.close()

    with open('Picture_rgb_Rom.coe', 'w') as f:
        f.writelines('memory_initialization_radix = 10;\nmemory_initialization_vector = ')
        for i in range(len(rgb)):
            if i % img.shape[1] == 0: 
                f.write('\n')
            f.write(str(rgb[i]).rjust(4) + ',')
    f.close()


    
    with open(f'{imgs_path}/{name}.bin', 'wb') as f:
        f.write(bytes(rgb))
    f.close()
    return rgb


# coe文件转换成图片
def coe2picture(): 
    infos_R = []
    with open('Picture_R_Rom.coe', 'r') as f:
        info = f.read().splitlines()
        for i in range(2, len(info)): 
            info1 = [int(a) for a in info[i].split(',')[:-1]]
            infos_R.append(info1)
    f.close()

    infos_G = []
    with open('Picture_G_Rom.coe', 'r') as f:
        info = f.read().splitlines()
        for i in range(2, len(info)): 
            info1 = [int(a) for a in info[i].split(',')[:-1]]
            infos_G.append(info1)
    f.close()

    infos_B = []
    with open('Picture_B_Rom.coe', 'r') as f:
        info = f.read().splitlines()
        for i in range(2, len(info)): 
            info1 = [int(a) for a in info[i].split(',')[:-1]]
            infos_B.append(info1)
    f.close()

    img_array = np.empty((np.array(infos_B).shape[0],np.array(infos_B).shape[1],3), dtype=int)
    if set_size == 1: 
        img_array = np.empty((img_h,img_w,3), dtype=int)

    for i in range(np.array(infos_B).shape[0]): 
        for j in range(np.array(infos_B).shape[1]):
            img_array[i][j][0] = infos_R[i][j]
            img_array[i][j][1] = infos_G[i][j]
            img_array[i][j][2] = infos_B[i][j]


    img_pil = Image.fromarray(np.uint8(img_array))
    img_pil.save('coe2picture.jpg')

if __name__ == '__main__': 
    imgs, img_names = gen_img()
    rgbs = []
    for img, name in zip(imgs, img_names):
        rgb = gen_coe(img, name)
        rgbs.append(rgb)
    with open("output.bin", "wb") as f:
        f.write(bytes(rgbs))
    #coe2picture()

