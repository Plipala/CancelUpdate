export ARCHS=armv7
include theos/makefiles/common.mk

TWEAK_NAME = CancelUpdate
CancelUpdate_FILES = Tweak.xm

BUNDLE_NAME = CancelUpdateLanguages
CancelUpdateLanguages_INSTALL_PATH = /var/mobile/Library/CancelUpdate

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk
