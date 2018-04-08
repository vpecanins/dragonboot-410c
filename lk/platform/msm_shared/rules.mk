LOCAL_DIR := $(GET_LOCAL_DIR)

INCLUDES += \
			-I$(LOCAL_DIR)/include

DEFINES += $(TARGET_XRES)
DEFINES += $(TARGET_YRES)

OBJS += \
	$(LOCAL_DIR)/debug.o \
	$(LOCAL_DIR)/smem.o \
	$(LOCAL_DIR)/smem_ptable.o \
	$(LOCAL_DIR)/jtag_hook.o \
	$(LOCAL_DIR)/jtag.o \
	$(LOCAL_DIR)/partition_parser.o \
	$(LOCAL_DIR)/hsusb.o \
	$(LOCAL_DIR)/boot_stats.o \
	$(LOCAL_DIR)/crc32.o

ifeq ($(ENABLE_WDOG_SUPPORT),1)
OBJS += \
	$(LOCAL_DIR)/wdog.o
endif

ifeq ($(ENABLE_SECAPP_LOADER), 1)
OBJS += $(LOCAL_DIR)/secapp_loader.o
endif

ifeq ($(ENABLE_QGIC3), 1)
OBJS += $(LOCAL_DIR)/qgic_v3.o
endif

ifeq ($(ENABLE_SMD_SUPPORT),1)
OBJS += \
	$(LOCAL_DIR)/rpm-smd.o \
	$(LOCAL_DIR)/smd.o
endif
ifeq ($(ENABLE_SDHCI_SUPPORT),1)
OBJS += \
	$(LOCAL_DIR)/sdhci.o \
	$(LOCAL_DIR)/sdhci_msm.o \
	$(LOCAL_DIR)/mmc_sdhci.o \
	$(LOCAL_DIR)/mmc_wrapper.o
else
OBJS += \
	$(LOCAL_DIR)/mmc.o
endif

ifeq ($(PLATFORM),msm8916)
	OBJS += $(LOCAL_DIR)/qgic.o \
		$(LOCAL_DIR)/qtimer.o \
		$(LOCAL_DIR)/qtimer_mmap.o \
		$(LOCAL_DIR)/interrupts.o \
		$(LOCAL_DIR)/clock.o \
		$(LOCAL_DIR)/clock_pll.o \
		$(LOCAL_DIR)/clock_lib2.o \
		$(LOCAL_DIR)/uart_dm.o \
		$(LOCAL_DIR)/board.o \
		$(LOCAL_DIR)/spmi.o \
		$(LOCAL_DIR)/bam.o \
		$(LOCAL_DIR)/scm.o \
		$(LOCAL_DIR)/qpic_nand.o \
		$(LOCAL_DIR)/dload_util.o \
		$(LOCAL_DIR)/gpio.o \
		$(LOCAL_DIR)/dev_tree.o \
                $(LOCAL_DIR)/qseecom_lk.o \
		$(LOCAL_DIR)/shutdown_detect.o \
		$(LOCAL_DIR)/certificate.o \
		$(LOCAL_DIR)/crypto_hash.o \
		$(LOCAL_DIR)/crypto5_eng.o \
		$(LOCAL_DIR)/crypto5_wrapper.o \
		$(LOCAL_DIR)/i2c_qup.o

endif

ifeq ($(ENABLE_BOOT_CONFIG_SUPPORT), 1)
	OBJS += \
		$(LOCAL_DIR)/boot_device.o
endif

ifeq ($(ENABLE_REBOOT_MODULE), 1)
	OBJS += $(LOCAL_DIR)/reboot.o
endif

ifeq ($(ENABLE_RPMB_SUPPORT), 1)
include platform/msm_shared/rpmb/rules.mk
ifeq ($(ENABLE_UFS_SUPPORT), 1)
        OBJS += $(LOCAL_DIR)/rpmb_ufs.o
endif
endif
