# Python program to illustrate
# arithmetic operation of
# bitwise AND of two images
    
# organizing imports
import cv2
import numpy as np
    
# path to input images are specified and  
# images are loaded with imread command 
img1 = cv2.imread('ace_of_spades_thesholded.png') 
img2 = cv2.imread('five_of_diamonds_thresholded.png')

img2 = cv2.resize(img2, (img1.shape[1],img1.shape[0]), interpolation = cv2.INTER_AREA)
 
# cv2.bitwise_and is applied over the
# image inputs with applied parameters

dest_and = cv2.bitwise_xor(img1, img1, mask = None)
 
# the window showing output image
# with the Bitwise AND operation
# on the input images
cv2.imshow('Bitwise XOR', dest_and)

#cv2.imwrite("bad_combo.png", dest_and)
  
# De-allocate any associated memory usage 
if cv2.waitKey(0) & 0xff == ord('q'):
    cv2.destroyAllWindows()