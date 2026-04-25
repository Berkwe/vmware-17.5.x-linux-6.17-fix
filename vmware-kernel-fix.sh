#!/bin/bash
# VMware 17.5.x + Linux 6.17 fix

set -e
WORKDIR=/tmp/vmware-fix-$(date +%s)
mkdir -p $WORKDIR && cd $WORKDIR

echo "[*] vmmon modülü yamalanıyor ve paketleniyor..."
tar -xf /usr/lib/vmware/modules/source/vmmon.tar
cp -r vmmon-only/include/* vmmon-only/shared/ 2>/dev/null || true

sed -i 's/del_timer_sync/timer_delete_sync/g' vmmon-only/linux/driver.c
sed -i 's/del_timer_sync/timer_delete_sync/g' vmmon-only/linux/hostif.c
sed -i 's/rdmsrl_safe/rdmsrq_safe/g' vmmon-only/linux/hostif.c

cat > vmmon-only/Makefile.kernel << 'MKEOF'
CC_OPTS += -DVMMON -DVMCORE
SRCROOT_ABS := PLACEHOLDER
INCLUDE := -I$(SRCROOT_ABS)/include -I$(SRCROOT_ABS)/include/x86 -I$(SRCROOT_ABS)/common -I$(SRCROOT_ABS)/linux -I$(SRCROOT_ABS)/shared -I$(SRCROOT_ABS)
ccflags-y := $(CC_OPTS) $(INCLUDE)
EXTRA_CFLAGS := $(CC_OPTS) $(INCLUDE)
obj-m += $(DRIVER).o
$(DRIVER)-y := $(subst $(SRCROOT_ABS)/, , $(patsubst %.c, %.o, $(wildcard $(SRCROOT_ABS)/linux/*.c $(SRCROOT_ABS)/common/*.c $(SRCROOT_ABS)/bootstrap/*.c)))
MKEOF

sed -i "s|PLACEHOLDER|$WORKDIR/vmmon-only|g" vmmon-only/Makefile.kernel

# DÜZELTME: vmmon manuel derlenmek yerine yeniden paketlenip kaynağa atılıyor.
tar -cf vmmon-fixed.tar vmmon-only
sudo cp vmmon-fixed.tar /usr/lib/vmware/modules/source/vmmon.tar

echo "[*] vmnet modülü yamalanıyor ve paketleniyor..."
tar -xf /usr/lib/vmware/modules/source/vmnet.tar
sed -i 's/read_lock(&dev_base_lock)/rcu_read_lock()/g' vmnet-only/vmnetInt.h
sed -i 's/read_unlock(&dev_base_lock)/rcu_read_unlock()/g' vmnet-only/vmnetInt.h

tar -cf vmnet-fixed.tar vmnet-only
sudo cp vmnet-fixed.tar /usr/lib/vmware/modules/source/vmnet.tar

echo "[*] vmware-modconfig ile tüm modüller derleniyor..."
sudo vmware-modconfig --console --install-all

sudo depmod -a
sudo modprobe vmmon
sudo modprobe vmnet
echo "✅ Kurulum Tamamlandı!"
