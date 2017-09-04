# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=Lithium
do.devicecheck=1
do.initd=0
do.modules=0
do.cleanup=1
device.name1=d855
device.name2=LG-D855
device.name3=LG
device.name4=G3
device.name5=LG-G3

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
is_slot_device=0;

## end setup

# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel install
dump_boot;

# begin ramdisk changes

if [ -f "init.rc" ]; then
  ui_print "[*] Applying kernel parameter changes" ;
  insert_line "init.rc" "init.kernel.params.rc" after "import /init.trace.rc" "import /init.msm8974ac.rc" ;
  insert_line "init.rc" "init.kernel.params.rc" after "import /init.trace.rc" "import /init.kernel.params.rc" ;
fi

if [ -f "init.g3.rc" ]; then
  ui_print "[*] Injecting MSM-IRQBalancer as a service";
  append_file "init.g3.rc" "msm_irqbalance" "msm_irqbalance_service.patch";
fi

ui_print "[*] Enabling frandom and erandom" ;
insert_line ueventd.rc "frandom" after "urandom" "/dev/frandom              0666   root       root\n";
insert_line ueventd.rc "erandom" after "urandom" "/dev/erandom              0666   root       root\n";

backup_file file_contexts;
insert_line file_contexts "frandom" after "urandom" "/dev/frandom				u:object_r:frandom_device:s0\n";
insert_line file_contexts "erandom" after "urandom" "/dev/erandom				u:object_r:erandom_device:s0\n";

# end ramdisk changes

write_boot;

## end install

ui_print "[*] Running fstrim and bumping the image";
mount /system ; fstrim /system && umount /system;
mount /data   ; fstrim /data   && umount /data;
mount /cache  ; fstrim /cache  && umount /cache;
tune2fs -o discard /dev/block/mmcblk0p40;
tune2fs -o discard /dev/block/mmcblk0p41;
tune2fs -o discard /dev/block/mmcblk0p43;

# bump image specific for LG G3
dd if=$bin/bump bs=1 count=32 >> /tmp/anykernel/boot-new.img;
dd if=/dev/zero of=$block;
dd if=/tmp/anykernel/boot-new.img of=$block;

