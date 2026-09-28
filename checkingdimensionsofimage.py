import cv2

img = cv2.imread("input.jpg")

rows, cols, channels = img.shape

print("cols:", cols)
print("rows:", rows)
print("Channels:", channels)