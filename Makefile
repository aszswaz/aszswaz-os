export SOURCE=src
export BUILD_DIR=build
export ASSEMBLER=nasm -I $(SOURCE)
export DD=dd

export OS_IMG=$(BUILD_DIR)/aszswaz.img
export MBR=$(BUILD_DIR)/mbr.bin
export OS_LOADER=$(BUILD_DIR)/os-loader.bin

IMG_SECTOR=1

all: $(BUILD_DIR) \
	$(OS_IMG)

$(BUILD_DIR):
	@mkdir -p $@

.PHONY: clean usb
clean:
	@rm -rf $(BUILD_DIR)

# 将镜像写入 USB
usb: $(OS_IMG)
	@sudo dd if=$(OS_IMG) of=/dev/sdc

# 制作 OS 镜像
$(OS_IMG): $(MBR)
	@$(DD) if=/dev/zero of=$@ bs=1M count=$(IMG_SECTOR) >> /dev/null 2>&1
	@$(DD) if=$(MBR) of=$@ bs=512 count=1 conv=notrunc >> /dev/null 2>&1
	@$(DD) if=$(OS_LOADER) of=$@ bs=512 seek=2 conv=notrunc >> /dev/null 2>&1

# 编译 MBR 程序
$(MBR): $(SOURCE)/mbr.asm \
		$(SOURCE)/config/boot.asm $(SOURCE)/config/global.asm \
		$(OS_LOADER)
	@./compile/mbr.sh $< $@

# OS 加载器
$(OS_LOADER): $(SOURCE)/os-loader.asm \
		$(SOURCE)/print.asm \
		$(SOURCE)/config/boot.asm $(SOURCE)/config/gdt.asm $(SOURCE)/config/global.asm
	@$(ASSEMBLER) $< -o $@
