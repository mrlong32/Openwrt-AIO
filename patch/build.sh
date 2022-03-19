#!/bin/bash
sudo chown -R 1000:1000 /home/build
# 修复upx异常
sudo apt-get update
sudo apt-get install upx git -y
ln -s /usr/bin/upx staging_dir/host/bin/upx

# 添加并安装源
echo "src-link custom /home/build/custom-feed" >> feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -p custom -a

cp -rf custom.config .config
make defconfig

# 获取编译的包列表
cd /home/build/custom-feed
ipk_list=($(git log  --name-status | grep -oP '(?<=\s)[-\w]+(?<!patch)(?=/)' | sort | uniq))
cd /home/build/openwrt

# 编译
for ipk in ${ipk_list[@]}
{
  echo "start compile $ipk"
  make package/$ipk/{clean,compile} -j2   || make package/$ipk/{clean,compile} V=s >> error/error_$ipk.log 2>&1 
}

# 移动Kmod
mvkmod(){
  if [ `find bin/targets -name $1` ];then
    if [ `find bin/packages -name $1` ];then
      for ipk in `find bin/packages -name $1`; do
        rm -f $ipk
      done
    fi
    for ipk in `find bin/targets -name $1`; do
      cp $ipk `find bin/packages -name custom`
    done
  fi
}

mvkmod "kmod-r8125*.ipk"

make package/index
