#aliyun
echo "将新硬盘分区"
echo "n
p



w
" | fdisk -u /dev/vdb

echo "格式化新分区"
mkfs -t ext4 /dev/vdb1

echo "将分区写入 /etc/fstab"
cp /etc/fstab /etc/fstabbak
echo `blkid /dev/vdb1 | awk '{print $2}' | sed 's/\"//g'` /mnt ext4 defaults 0 0 >> /etc/fstab
df -h

echo "将新分区挂载到 /mnt "
mount /dev/vdb1 /mnt

echo "******查看最终结果******"
df -h