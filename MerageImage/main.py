from PIL import Image
import os
import glob
import shutil

def merge_images(offset=0):
    """ 支持多格式图片输入 """
    # 常量定义
    INPUT_DIR = './originImg'
    OUTPUT_DIR = './export'
    VALID_SIZES = {(512, 910), (512, 725)}
    SUPPORTED_EXTS = ('.png', '.jpg', '.jpeg')  # 新增支持的扩展名
    
    # 清空输出目录
    # if os.path.exists(OUTPUT_DIR):
    #     shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 加载并分类图片（修改文件获取逻辑）
    size_groups = {
        (512, 910): [],
        (512, 725): []
    }
    
    # 获取所有支持的图片文件（关键修改点）
    image_paths = []
    for filename in os.listdir(INPUT_DIR):
        if filename.lower().endswith(SUPPORTED_EXTS):
            image_paths.append(os.path.join(INPUT_DIR, filename))
    image_paths = sorted(image_paths)  # 保持排序逻辑
    
    if not image_paths:
        print("错误：未找到任何图片文件（支持格式：PNG/JPG/JPEG）")
        return

    for path in image_paths:
        try:
            img = Image.open(path)
            if img.size not in VALID_SIZES:
                raise ValueError(f"无效尺寸：{os.path.basename(path)} {img.size}")

            # 统一处理透明通道（兼容JPG/PNG）
            if img.mode == 'RGBA':
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3])
                img = background
            else:
                img = img.convert('RGB')

            size_groups[img.size].append(img)
        except Exception as e:
            print(f"处理图片出错：{path}\n{str(e)}")
            return

    # 处理每个尺寸组（后续逻辑保持不变）
    for (width, height), images in size_groups.items():
        if not images:
            continue

        total = len(images)
        effective_offset = offset % total
        sorted_images = images[effective_offset:] + images[:effective_offset]

        rows = 2
        cols = 4
        merged_height = height * rows
        num_merged = (total + 7) // 8

        for i in range(num_merged):
            canvas = Image.new('RGB', (2048, merged_height), (255, 255, 255))
            
            for j in range(8):
                img_index = (i * 8 + j) % total
                x = (j % cols) * width
                y = (j // cols) * height
                canvas.paste(sorted_images[img_index], (x, y))

            suffix = f"{height}"
            output_path = os.path.join(OUTPUT_DIR, f'merged_{suffix}_{i:04d}.jpg')
            canvas.save(output_path, format='JPEG', quality=95)

    print(f"处理完成，偏移量：{offset}")

if __name__ == "__main__":
    merge_images(offset=0)  # 设置需要的偏移量