import cv2
import numpy as np
from PIL import ImageFont, ImageDraw, Image
import os

# Globals
ref_point = []
cropping = False
new_text = ""
image = None
clone = None
typing_mode = False
custom_font_path = "DM_Serif_Text,PT_Sans,Roboto,Tinos\PT_Sans\PTSans-Regular.ttf"  # Update to your font path

def click_and_crop(event, x, y, flags, param):
    global ref_point, cropping, image

    if event == cv2.EVENT_LBUTTONDOWN:
        ref_point.clear()
        ref_point.append((x, y))
        cropping = True

    elif event == cv2.EVENT_LBUTTONUP:
        ref_point.append((x, y))
        cropping = False
        # Draw rectangle on fresh clone to avoid multiple rectangles
        image[:] = clone.copy()
        # cv2.rectangle(image, ref_point[0], ref_point[1], (0, 255, 0), 2)
        cv2.imshow("Image", image)

def fit_text_to_rectangle(draw, text, rect_w, rect_h, font_path):
    # Find max font size that fits inside the rectangle width and height
    font_size = 100  # Start big
    while font_size > 5:
        font = ImageFont.truetype(font_path, font_size)
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        if text_w <= rect_w and text_h <= rect_h:
            return font, text_w, text_h
        font_size -= 1
    # fallback smallest font
    font = ImageFont.truetype(font_path, 5)
    bbox = draw.textbbox((0, 0), text, font=font)
    return font, bbox[2]-bbox[0], bbox[3]-bbox[1]

def replace_text_in_rectangle():
    global new_text, ref_point, image, clone, custom_font_path

    if len(ref_point) == 2 and new_text.strip() != "":
        x1, y1 = ref_point[0]
        x2, y2 = ref_point[1]
        x, y = min(x1, x2), min(y1, y2)
        w, h = abs(x2 - x1), abs(y2 - y1)

        # 1. Create a clean white rectangle (completely removes everything)
        image[y:y+h, x:x+w] = 255  # Fill with white using numpy slicing

        # 2. Convert to PIL for text handling
        pil_img = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        draw = ImageDraw.Draw(pil_img)

        # 3. Find optimal font size
        font_size = 1
        optimal_font = None
        while True:
            try:
                test_font = ImageFont.truetype(custom_font_path, font_size)
                bbox = draw.textbbox((0, 0), new_text, font=test_font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                
                if text_width > w or text_height > h:
                    font_size -= 1
                    optimal_font = ImageFont.truetype(custom_font_path, font_size)
                    break
                font_size += 1
            except:
                print("Error loading font")
                return

        # 4. Calculate centered position
        bbox = draw.textbbox((0, 0), new_text, font=optimal_font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = x + (w - text_width) // 2
        text_y = y + (h - text_height) // 2 - bbox[1]

        # 5. Draw the text
        draw.text((text_x, text_y), new_text, font=optimal_font, fill="black")

        # 6. Convert back to OpenCV
        image[:] = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        
        # 7. CRITICAL: Force complete refresh of the display
        clone = image.copy()
        ref_point.clear()
        
        # 8. Force immediate redraw
        cv2.imshow("Image", image)

def main(image_path):
    global image, clone, new_text, typing_mode, ref_point

    image = cv2.imread(image_path)
    if image is None:
        print("Failed to load image.")
        return

    clone = image.copy()
    cv2.namedWindow("Image")
    cv2.setMouseCallback("Image", click_and_crop)

    print("📌 Instructions:")
    print("- Draw a rectangle with your mouse.")
    print("- Press 't' to start typing your new text.")
    print("- Press ENTER to apply text.")
    print("- Press BACKSPACE to delete text while typing.")
    print("- Press 's' to save the image.")
    print("- Press 'r' to reset the image.")
    print("- Press 'q' to quit.")

    while True:
            # Always show clean image without temporary rectangles
        display = image.copy()
        
        # Only show typing status if in typing mode
        if typing_mode:
            cv2.putText(display, f"Input: {new_text}_", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        
        cv2.imshow("Image", display)
        key = cv2.waitKey(1) & 0xFF


        if key == ord("t") and len(ref_point) == 2 and not typing_mode:
            typing_mode = True
            new_text = ""

        elif typing_mode:
            if key == 13 or key == 10:  # ENTER
                typing_mode = False
                replace_text_in_rectangle()

            elif key == 8:  # BACKSPACE
                new_text = new_text[:-1]

            elif 32 <= key <= 126:  # Printable chars
                new_text += chr(key)

        elif key == ord("r"):
            image = cv2.imread(image_path)
            clone[:] = image.copy()
            ref_point.clear()
            new_text = ""
            typing_mode = False

        elif key == ord("s"):
            cv2.imwrite("output_custom_font.png", image)
            print("✅ Saved as output_custom_font.png")

        elif key == ord("q"):
            break

    cv2.destroyAllWindows()

if __name__ == "__main__":
    main("payment.jpg")
