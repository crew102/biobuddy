# dlib needed for detector loading
import dlib
import cv2


def one_detection(detector, img_path):
  
  img = cv2.imread(img_path)
  img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

  dets = detector(img, upsample_num_times=1)

  first = dets[0]
  
  x1 = first.rect.left()
  y1 = first.rect.top()
  
  x2 = first.rect.right()
  y2 = first.rect.bottom()
  
  return x1, y1, x2, y2
