from matplotlib import pyplot as plt
import matplotlib.patches as mpatches
import numpy as np 
from sympy import symbols, Eq, solve
from matplotlib.lines import Line2D
import math


x_list = np.linspace (0, 360, 36000)
y_list = []

for x in x_list: 
    if (x == 0): 
        y = 31.5
        y_list.append(y)
    if (x > 0 and x <= 54.46): 
        y = math.sqrt((31.5*math.tan(x * math.pi / 180))**2 + (31.5)**2)
        y_list.append(y)
    if (x > 54.46 and x < 90):
        y= math.sqrt((44.1/math.tan(x * math.pi / 180))**2+(44.1)**2)
        y_list.append(y)
    if (x == 90): 
        y = 44.1
        y_list.append(y)

    if (x > 90 and x <= 125.54): 
        y= math.sqrt((44.1/math.tan(-x* math.pi / 180))**2+(44.1)**2)
        y_list.append(y)
    if (x > 125.54 and x < 180):
        y = math.sqrt((31.5*math.tan(x * math.pi / 180))**2 + (31.5)**2)
        y_list.append(y)
    if (x == 180): 
        y = -31.5
        y_list.append(y)

    if (x > 180 and x <= 234.46): 
        y = math.sqrt((31.5*math.tan(-x * math.pi / 180))**2 + (31.5)**2)
        y_list.append(y)
    if (x > 234.46 and x < 270):
        y= math.sqrt((44.1/math.tan(-x * math.pi / 180))**2+(44.1)**2)
        y_list.append(y)
    if (x == 270): 
        y = -44.1
        y_list.append(y)

    if (x > 270 and x <= 305.54): 
        y= math.sqrt((44.1/math.tan(-x * math.pi / 180))**2+(44.1)**2)
        y_list.append(y)
    if (x > 305.54 and x < 360):
        y = math.sqrt((31.5*math.tan(x * math.pi / 180))**2 + (31.5)**2)
        y_list.append(y)
    if (x == 360): 
        y = 31.5
        y_list.append(y)
    

plt.plot(x_list,y_list, color='red')
plt.xlabel('\u03B8 (\u00B0)')
plt.ylabel('d (mm)')
plt.xlim([0, 360])
plt.ylim([0, 60])
plt.title('Distance from Center vs. Angle')
plt.show()