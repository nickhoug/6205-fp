from PIL import Image
import numpy as np

def clear_comments(file_path): 
    with open(f'{file_path}','r') as f:
        lines = f.readlines() 
    with open(f'{file_path[:len(file_path)-4]}_processed.mem','w') as new_f:
        for line in lines:
            if not (line.startswith("//") or line.startswith("x")):
                new_f.write(line)
    return 

def hex_to_binary(hex_string):
    HEX_TO_BINARY_CONVERSION_TABLE = {
                              '0': '0000',

                              '1': '0001',

                              '2': '0010',

                              '3': '0011',

                              '4': '0100',

                              '5': '0101',

                              '6': '0110',

                              '7': '0111',

                              '8': '1000',

                              '9': '1001',

                              'a': '1010',

                              'b': '1011',

                              'c': '1100',

                              'd': '1101',

                              'e': '1110',

                              'f': '1111'}
    binary_string = ""
    for character in hex_string:
        binary_string += HEX_TO_BINARY_CONVERSION_TABLE[character]
    return binary_string

def binary(num, length=8):
    return format(num, '#0{}b'.format(length + 2))

def bin_to_hex(string):  
    dec_str = format(int(string, 2),'x')
    dec_str.rjust(4,'0')
    return dec_str

def test_1(i, j, file_path): 
    width, height = 320, 240

    im = Image.open(file_path) 
    im = im.resize((height, width), Image.BILINEAR)
    im = np.array(im)

    bit_24 = im[i][j]
    R, G, B = binary(im[i][j][0]), binary(im[i][j][1]), binary(im[i][j][2])
    bit_16 = binary(im[i][j][0])[2:7] + binary(im[i][j][1])[2:8] + binary(im[i][j][2])[2:7]
    bit_hex = bin_to_hex(bit_16)

    print(bit_24)
    print(R, G, B)
    print(bit_16)
    print(bit_hex)

    return 

def test_2(i, j, file_path_name): 
    width, height = 320, 240

    im = Image.open(f'test_images/{file_path_name}.png') 
    im = im.resize((height, width), Image.BILINEAR)
    im = np.array(im)

    im_png = np.zeros((1,1,3), dtype=np.int8)

    with open(f'test_mem/{file_path_name}.mem', 'w') as f:
        binary_pixel = binary(im[i][j][0])[2:7] + binary(im[i][j][1])[2:8] + binary(im[i][j][2])[2:7]
        hex_value = bin_to_hex(binary_pixel)
        f.write(f'{hex_value}\n')
        print('PNG pixel in RGB:', im[i][j])
        print('PNG pixel in Binary:', binary_pixel)
        print('PNG pixel in Hex:', hex_value)
    
    f.close()

    with open(f'test_mem/{file_path_name}.mem','r') as f:
        hex_value = f.read(4)
        binary_value = hex_to_binary(hex_value)
        R, G, B = binary_value[0:5] + '000', binary_value[5:11] + '00', binary_value[11:16] + '000'
        R_int, G_int, B_int = int(R, 2), int(G, 2), int(B, 2)

        im_png[0][0][0] = R_int
        im_png[0][0][1] = G_int
        im_png[0][0][2] = B_int
        f.read(1)

        print('')
        print('MEM pixel in Hex:', hex_value)
        print('MEM pixel in Binary:', binary_value)   
        print('MEM pixel in RGB:', im_png[0][0])

        print('')
        print(R_int, type(R_int))

    return 

def png_to_mem(file_path):
    width, height = 240, 320

    im = Image.open(file_path) 
    im = im.resize((width, height), Image.BILINEAR)
    im = np.array(im) #im.shape -> (320, 240, 3) -> (Height, Width, Depth)

    with open(f'mem_test/{file_path[12:len(file_path)-4]}.mem', 'w') as f:
        for j in list(range(height)): 
            for i in list(range(width)): 
                binary_pixel = binary(im[j, i][0])[2:7] + binary(im[j, i][1])[2:8] + binary(im[j, i][2])[2:7] # <class 'str'>
                hex_value = bin_to_hex(binary_pixel)
                f.write(f'{hex_value}\n')
    return 

def mem_to_png_RGB(file_path):

    height, width = 320, 240

    im = np.zeros((height, width, 3), dtype=np.int8) 

    ###

    with open(f'{file_path}','r') as f: 
        for i in list(range(width)): 
            for j in list(range(height)): 
                hex_value = f.read(4)
                binary_value = hex_to_binary(hex_value)
                R, G, B = binary_value[0:5] + '000', binary_value[5:11] + '00', binary_value[11:16] + '000'
                R_int, G_int, B_int = int(R, 2), int(G, 2), int(B, 2)
                im[j][i][0] = R_int
                im[j][i][1] = G_int
                im[j][i][2] = B_int
                f.read(1)

    processed_image = Image.fromarray(im, 'RGB')
    processed_image.save(f'blurred_images/{file_path[9:len(file_path) - 4]}_thresh.png')
    return 

def mem_to_png_L(file_path):

    height, width = 320, 240

    im = np.zeros((height, width), dtype=np.int8) # shape = (height, width)

    with open(f'{file_path}','r') as f:  
        for j in list(range(height)): 
            for i in list(range(width)):
                hex_value = f.read(4)
                binary_value = hex_to_binary(hex_value)
                L = int(binary_value[8:], 2)
                im[j, i] = L
                f.read(1)

    processed_image = Image.fromarray(im, 'L')
    processed_image.save(f'images_thresh/{file_path[11:len(file_path) - 14]}_mask_new.png')
    return 

def crosshair(file_path, x, y): 
    width, height = 240, 320

    im = Image.open(file_path) 
    im = im.convert("RGB")
    im = np.array(im)
    im = np.resize(im, (height, width, 3))

    for j in list(range(height)): #vertical line
        im[j][x][0] = 255
        im[j][x][1] = 20
        im[j][x][2] = 147

    for i in list(range(width)): #horizontal line
        im[y][i][0] = 255
        im[y][i][1] = 20
        im[y][i][2] = 147

    processed_image = Image.fromarray(im, 'RGB')
    processed_image.save(f'images_crosshair/{file_path[14:len(file_path) - 4]}_crosshair.png')

    return 

def edges(file_path, left, right, top, bot): 
    width, height = 240, 320

    im = Image.open(file_path) 
    im = im.convert("RGB")
    im = np.array(im)
    im = np.resize(im, (height, width, 3))

    for j in list(range(height)): #vertical line - left & right
        im[j][left][0] = 255
        im[j][left][1] = 20
        im[j][left][2] = 147
        im[j][right][0] = 255
        im[j][right][1] = 20
        im[j][right][2] = 147

    for i in list(range(width)): #horizontal line - top & bot
        im[top][i][0] = 255
        im[top][i][1] = 20
        im[top][i][2] = 147 
        im[bot][i][0] = 255
        im[bot][i][1] = 20
        im[bot][i][2] = 147 

    processed_image = Image.fromarray(im, 'RGB')
    processed_image.save(f'images_edges/{file_path[14:len(file_path) - 4]}_edges.png')
        
    return

card_name = 'king_of_clubs'

#png_to_mem(f'images_test/{card_name}_test.png')
#clear_comments(f'mem_thresh/{card_name}_thresh.mem')
#mem_to_png_L(f'mem_thresh/{card_name}_thresh_processed.mem')
#crosshair(f'images_thresh/{card_name}_thresh_mask.png', 114, 153)
edges(f'images_thresh/{card_name}_thresh_mask.png', 73, 155, 95, 211)
