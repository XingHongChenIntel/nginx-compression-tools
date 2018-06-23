#! /bin/bash

#check ICP_ROOT
: ${ICP_ROOT?}
UPSTREAM_DRV_OUT=$ICP_ROOT/build
CP="/usr/bin/cp";

function print_usage()
{
  echo "optional args:"
  echo "-C|--CyInstances: the number of compress instances"
  echo "-D|--DcInstances: the number of decompress instances"
  echo "-P|--ProcessInstances: the number of process instances"
  echo "-L|--LimitDevAccess: limit device access"
  echo "-H|--HpNum: the number of system huge pages"
  echo "-N|--NUM: how many qat engines are enabled"
  echo "-S|--SHARE"
}

#Migrate below line form Makefile in $ICP_ROOT
INTEL_VENDORID="8086"
DH895_DEVICE_NUMBER="0435"
DH895_DEVICE_NUMBER_VM="0443"
C62X_DEVICE_NUMBER="37c8"
C62X_DEVICE_NUMBER_VM="37c9"
D15XX_DEVICE_NUMBER="6f54"
D15XX_DEVICE_NUMBER_VM="6f55"
C3XXX_DEVICE_NUMBER="19e2"
C3XXX_DEVICE_NUMBER_VM="19e3"
C4XXX_DEVICE_NUMBER="18a0"
E4XXX_DEVICE_NUMBER="4940"   # for cpm2.0 4xxx
E4XXX_DEVICE_NUMBER_VM="4941"   # for cpm2.0 VM 4xxx
C4XXX_DEVICE_NUMBER_VM="18a1"
E200XX_DEVICE_NUMBER="18ee"
numC62xDevice=`lspci -vnd 8086: | egrep -c "37c8|37c9"`
numD15xxDevice=`lspci -vnd 8086: | egrep -c "6f54|6f55"`
numDh895xDevice=`lspci -vnd 8086: | egrep -c "0435|0443"`
numC3xxxDevice=`lspci -vnd 8086: | egrep -c "19e2|19e3"`
numC4xxxDevice=`lspci -vnd 8086: | egrep -c "18a0|18a1"`
numE200xxDevice=`lspci -vnd 8086: | egrep -c "18ee"`
numDh895xDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${DH895_DEVICE_NUMBER}"`
numDh895xDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${DH895_DEVICE_NUMBER_VM}"`
numC62xDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${C62X_DEVICE_NUMBER}"`
numC62xDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${C62X_DEVICE_NUMBER_VM}"`
numD15xxDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${D15XX_DEVICE_NUMBER}"`
numD15xxDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${D15XX_DEVICE_NUMBER_VM}"`
numC3xxxDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${C3XXX_DEVICE_NUMBER}"`
numC3xxxDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${C3XXX_DEVICE_NUMBER_VM}"`
numC4xxxDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${C4XXX_DEVICE_NUMBER}"`
numC4xxxDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${C4XXX_DEVICE_NUMBER_VM}"`
numE4xxxDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${E4XXX_DEVICE_NUMBER}"`
numE4xxxDevicesV=`lspci -n | egrep -c "${INTEL_VENDORID}:${E4XXX_DEVICE_NUMBER_VM}"`
numE200xxDevicesP=`lspci -n | egrep -c "${INTEL_VENDORID}:${E200XX_DEVICE_NUMBER}"`

if [ $numC62xDevice != "0" ] ; then
  numberOfCPM=$numC62xDevice
elif [ $numDh895xDevice != "0" ]; then
  numberOfCPM=$numDh895xDevice
elif [ $numC3xxxDevice != "0" ]; then
  numberOfCPM=$numC3xxxDevice
elif [ $numC4xxxDevice != "0" ]; then
  numberOfCPM=$numC4xxxDevice
elif [ $numE200xxDevice != "0" ]; then
  numberOfCPM=$numE200xxDevice
else
  numberOfCPM=0
fi
NUM_DEV=0

#default configuration
if [[ $numC62xDevicesV != "0" || $numE4xxxDevicesV != "0" ]] ; then
  declare -i DefaultNumberCyInstances=1
  declare -i DefaultNumberDcInstances=1
  declare -i DefaultNumProcesses=2
else
  declare -i DefaultNumberCyInstances=0
  declare -i DefaultNumberDcInstances=4
  declare -i DefaultNumProcesses=1
fi
declare -i DEFAULT_MAX_HP=2048
declare -i DEFAULT_MAX_HPP=256
declare -i LimitDevAccess=0

#check the input arguments
set -o errexit
GETOPT_ARGS=`getopt -o C:D:P:H:N:L::Sh \
             -l CyInstances:,DcInstances:,ProcessInstances:,HpNum:,NUM:,LimitDevAccess::,SHARE,help \
             -- "$@"`
eval set -- "$GETOPT_ARGS"
while [ true ]
do
  case "$1" in
    -C|--CyInstances)
      if [ -n "$(echo $2| sed -n "/^[0-9]\+$/p")" ];then
        NumberCyInstances=$2; shift 2
      else
        echo "[ERROR] parameter:-C|--CyInstances $2"; exit 1
      fi
      ;;
    -D|--DcInstances)
      if [ -n "$(echo $2| sed -n "/^[0-9]\+$/p")" ];then
        NumberDcInstances=$2; shift 2
      else
        echo "[ERROR] parameter:-D|--DcInstances $2"; exit 1
      fi
      ;;
    -P|--ProcessInstances)
      if [ -n "$(echo $2| sed -n "/^[0-9]\+$/p")" ];then
        NumProcesses=$2; shift 2
      else
        echo "[ERROR] parameter:-P|--ProcessInstances $2"; exit 1
      fi
      ;;
    -L|--LimitDevAccess)
      if [[ $2 == "0" || $2 == "1" ]];then
        LimitDevAccess=$2; shift 2
      elif [ -z "$2" ];then
        LimitDevAccess=1; shift 2
      else
        echo "[ERROR] parameter:-L|--LimitDevAccess $2"; exit 1
      fi
      ;;
    -H|--HpNum)
      if [ -n "$(echo $2| sed -n "/^[0-9]\+$/p")" ];then
        MAX_HP=$2; MAX_HPP=$2; shift 2
      else
        echo "[ERROR] parameter:-H|--HpNum $2"; exit 1
      fi
      ;;
    -N|--NUM)
      NUM_DEV=$2;
      if [ -n "$(echo $2| sed -n "/^[0-9]\+$/p")" ];then
        [[ $2 -gt $numberOfCPM ]] && (echo "[ERROR] parameter:-N|--NUM $2";exit 1)
        NUM_DEV=$2; shift 2
      else
        echo "[ERROR] parameter:-N|--NUM $2"; exit 1
      fi
      ;;
    -S|--SHARE)
      SHARED_SHIM="share"; shift;;
    -h|--help)
      print_usage; exit 1;;
    *)
      break;;
  esac
done

cd $UPSTREAM_DRV_OUT
NumberCyInstances=${NumberCyInstances:-$DefaultNumberCyInstances}
NumberDcInstances=${NumberDcInstances:-$DefaultNumberDcInstances}
NumProcesses=${NumProcesses:-$DefaultNumProcesses}
if [ $numC62xDevicesP != "0" ] ; then
  if [ ! -f intel_qat.ko ] ||
     [ ! -f qat_c62x.ko ]  ||
     [ ! -f usdm_drv.ko ]  ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f c6xx_dev0.conf ]] && ( echo "c6xx_dev0.conf not exist"; exit 1 )
  dev_conf_file="c6xx_dev0.conf"
  if [ $NumberCyInstances -eq 0 ] ; then
    if [ $((NumberDcInstances * NumProcesses)) -gt 128 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  elif [ $NumberDcInstances -eq 0 ] ; then
    if [ $((NumberCyInstances * NumProcesses)) -gt 64 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  else
    if [ $((NumberDcInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    elif [ $((NumberCyInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  fi
elif [ $numDh895xDevicesP != "0" ]; then
  if [ ! -f intel_qat.ko ]    ||
     [ ! -f qat_dh895xcc.ko ] ||
     [ ! -f usdm_drv.ko ]     ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f dh895xcc_dev0.conf ]] && ( echo "dh895xcc_dev0.conf not exist"; exit 1 )
  dev_conf_file="dh895xcc_dev0.conf"
  if [ $NumberCyInstances -eq 0 ] ; then
    if [ $((NumberDcInstances * NumProcesses)) -gt 128 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  elif [ $NumberDcInstances -eq 0 ] ; then
    if [ $((NumberCyInstances * NumProcesses)) -gt 64 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  else
    if [ $((NumberDcInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    elif [ $((NumberCyInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  fi
elif [ $numC3xxxDevicesP != "0" ]; then
  if [ ! -f intel_qat.ko ]    ||
     [ ! -f qat_c3xxx.ko ]    ||
     [ ! -f qat_c3xxxvf.ko ]  ||
     [ ! -f usdm_drv.ko ]     ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f c3xxx_dev0.conf ]] && ( echo "c3xxx_dev0.conf not exist"; exit 1 )
  dev_conf_file="c3xxx_dev0.conf"
  if [ $NumberCyInstances -eq 0 ] ; then
    if [ $((NumberDcInstances * NumProcesses)) -gt 128 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  elif [ $NumberDcInstances -eq 0 ] ; then
    if [ $((NumberCyInstances * NumProcesses)) -gt 64 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  else
    if [ $((NumberDcInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    elif [ $((NumberCyInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  fi
elif [ $numC4xxxDevicesP != "0" ]; then
  if [ ! -f intel_qat.ko ]    ||
     [ ! -f qat_c4xxx.ko ]    ||
     [ ! -f qat_c4xxxvf.ko ]  ||
     [ ! -f usdm_drv.ko ]     ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f c4xxx_dev0.conf ]] && ( echo "c4xxx_dev0.conf not exist"; exit 1 )
  ##########################################################################
  #To-Do: For different c4 platform we need use different file.
  ##########################################################################
  dev_conf_file="c4xxx_dev0.conf"
  if [ $(((NumberCyInstances * NumProcesses) + ((NumberDcInstances * NumProcesses)/2))) -gt 256 ] ; then
    echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
    echo "             NumProcesses=$NumProcesses"
    exit 1
  fi
elif [ $numE4xxxDevicesP != "0" ]; then
  if [ ! -f intel_qat.ko ]    ||
     [ ! -f qat_4xxx.ko ]    ||
     [ ! -f qat_4xxxvf.ko ]  ||
     [ ! -f usdm_drv.ko ]     ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f 4xxx_dev0.conf ]] && ( echo "4xxx_dev0.conf not exist"; exit 1 )
  ##########################################################################
  #To-Do: For different c4 platform we need use different file.
  ##########################################################################
  dev_conf_file="4xxx_dev0.conf"
  if [ $(((NumberCyInstances * NumProcesses) + ((NumberDcInstances * NumProcesses)/2))) -gt 64 ] ; then
    echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
    echo "             NumProcesses=$NumProcesses"
    exit 1
  fi

elif [ $numC62xDevicesV != "0" ] ; then
  if [ ! -f intel_qat.ko ] ||
     [ ! -f qat_c62x.ko ]  ||
     [ ! -f qat_c62xvf.ko ]  ||
     [ ! -f usdm_drv.ko ]  ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f c6xxvf_dev0.conf.vm ]] && ( echo "c6xxvf_dev0.conf not exist"; exit 1 )
  dev_conf_file="c6xxvf_dev0.conf.vm"
elif [ $numE4xxxDevicesV != "0" ] ; then
  if [ ! -f intel_qat.ko ] ||
     [ ! -f qat_c62x.ko ]  ||
     [ ! -f qat_c62xvf.ko ]  ||
     [ ! -f usdm_drv.ko ]  ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f 4xxxvf_dev0.conf.vm ]] && ( echo "4xxxvf_dev0.conf not exist"; exit 1 )
  dev_conf_file="4xxxvf_dev0.conf.vm"
elif [ $numE200xxDevicesP != "0" ] ; then
  if [ ! -f intel_qat.ko ] ||
     [ ! -f qat_200xx.ko ]  ||
     [ ! -f usdm_drv.ko ]  ||
     [ ! -f adf_ctl ] ; then
    echo "lost driver files, please compile it first"
    exit 1
  fi
  [[ ! -f 200xx_dev0.conf ]] && ( echo "200xx_dev0.conf not exist"; exit 1 )
  dev_conf_file="200xx_dev0.conf"
  if [ $NumberCyInstances -eq 0 ] ; then
    if [ $((NumberDcInstances * NumProcesses)) -gt 128 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  elif [ $NumberDcInstances -eq 0 ] ; then
    if [ $((NumberCyInstances * NumProcesses)) -gt 64 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  else
    if [ $((NumberDcInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    elif [ $((NumberCyInstances * NumProcesses)) -gt 32 ] ; then
      echo "Error input: NumberCyInstances=$NumberCyInstances, NumberDcInstances=$NumberDcInstances"
      echo "             NumProcesses=$NumProcesses"
      exit 1
    fi
  fi
else
    echo "unknown platform... Exit"
    exit 1

fi

#set configurable parameters according to input options
${CP} -f $dev_conf_file dev.conf
kernel_section_linenumber=$(cat -n dev.conf | grep "Kernel Instances Section for QAT API" |awk '{print $1}')
if [ $kernel_section_linenumber ] ; then
    kernel_section_start=$((kernel_section_linenumber - 1))
    kernel_section_end_linenumber=$(grep -n "Data Compression - Kernel instance #" dev.conf | awk -F: '{print $1}' | tail -n 1)
    kernel_section_end=$((kernel_section_end_linenumber + 4))
    sed -i "$kernel_section_start, $kernel_section_end d" dev.conf
fi
sed -i -e '/^\[KERNEL\]/,/^#/s/\(NumberCyInstances = \)[0-9].*/\10/'                              \
       -e '/^\[KERNEL\]/,/^#/s/\(NumberDcInstances = \)[0-9].*/\10/'                              \
       -e '/^\[SSL\]/,/^LimitDevAccess/s/\(NumberCyInstances = \)[0-9].*/\1'$NumberCyInstances'/' \
       -e '/^\[SSL\]/,/^LimitDevAccess/s/\(NumberDcInstances = \)[0-9].*/\1'$NumberDcInstances'/' \
       -e '/^\[SSL\]/,/^LimitDevAccess/s/\(NumProcesses = \)[0-9].*/\1'$NumProcesses'/' dev.conf

sed -i '/#[1-6]$/,/^$/d' dev.conf
if [[ $numE4xxxDevicesP != "0" ]] ; then
   sed -i 's/sym/asym/g' dev.conf
fi
line=$(grep -n '\"SSL0\"' dev.conf | cut -d: -f 1)

if [[ $numC62xDevicesP != "0" || $numDh895xDevicesP != "0" || $numC3xxxDevicesP != "0" || \
      $numC62xDevicesV != "0" || $numE4xxxDevicesP != "0" || $numE4xxxDevicesV != "0" || $numE200xxDevicesP != "0" ]] ; then
    s_line=$((line - 1)); e_line=$((line + 4))
    for((j = $NumberCyInstances; j > 1; j--)); do
      sed -i -e '1,'$((s_line-1))'h; '$s_line'h; '$((s_line+1))','$e_line'H; '$((e_line))'G' \
             -e ''$e_line','$((e_line+5))'s/#0/#'$((j-1))'/'                                 \
             -e ''$e_line','$((e_line+5))'s/Cy0/Cy'$((j-1))'/g'                              \
             -e  ''$e_line','$((e_line+5))'s/SSL0/SSL'$((j-1))'/g'                           \
             -e ''$e_line','$((e_line+5))'s/Affinity = 1/Affinity ='$j'/' dev.conf
    done
    [[ $NumberCyInstances -eq 0 ]] && sed -i ''$line','$((e_line-1))'s/^/#/' dev.conf

    line=$(grep -n '\"Dc0\"' dev.conf | cut -d: -f 1)
    s_line=$((line - 1)); e_line=$((line + 4))
    for((j = $NumberDcInstances; j > 1; j--)); do
      sed -i -e '1,'$((s_line-1))'h; '$s_line'h; '$((s_line+1))','$e_line'H; '$((e_line))'G' \
             -e ''$e_line','$((e_line+5))'s/#0/#'$((j-1))'/'                                 \
             -e ''$e_line','$((e_line+5))'s/Dc0/Dc'$((j-1))'/g'                              \
             -e ''$e_line','$((e_line+5))'s/Affinity = 1/Affinity ='$j'/' dev.conf
    done
elif [ $numC4xxxDevicesP != "0" ]; then
    s_line=$((line - 1)); e_line=$((line + 5))
    for((j = $NumberCyInstances; j > 1; j--)); do
      sed -i -e '1,'$((s_line-1))'h; '$s_line'h; '$((s_line+1))','$e_line'H; '$((e_line))'G' \
             -e ''$e_line','$((e_line+5))'s/#0/#'$((j-1))'/'                                 \
             -e ''$e_line','$((e_line+5))'s/Cy0/Cy'$((j-1))'/g'                              \
             -e  ''$e_line','$((e_line+5))'s/SSL0/SSL'$((j-1))'/g'                           \
             -e ''$e_line','$((e_line+5))'s/Affinity = 1/Affinity ='$j'/' dev.conf
    done
    [[ $NumberCyInstances -eq 0 ]] && sed -i ''$line','$((e_line-1))'s/^/#/' dev.conf

    line=$(grep -n '\"Dc0\"' dev.conf | cut -d: -f 1)
    s_line=$((line - 1)); e_line=$((line + 5))
    for((j = $NumberDcInstances; j > 1; j--)); do
      sed -i -e '1,'$((s_line-1))'h; '$s_line'h; '$((s_line+1))','$e_line'H; '$((e_line))'G' \
             -e ''$e_line','$((e_line+5))'s/#0/#'$((j-1))'/'                                 \
             -e ''$e_line','$((e_line+5))'s/Dc0/Dc'$((j-1))'/g'                              \
             -e ''$e_line','$((e_line+5))'s/Affinity = 1/Affinity ='$j'/' dev.conf
    done
fi

[[ $NumberDcInstances -eq 0 ]] && sed -i ''$line','$((e_line-1))'s/^/#/' dev.conf
if [ $numC4xxxDevice == "0" ]; then
  [[ $NumberDcInstances -eq 0 ]] && sed -i 's/ServicesEnabled.*/ServicesEnabled = cy/' dev.conf
  [[ $NumberCyInstances -eq 0 ]] && sed -i 's/ServicesEnabled.*/ServicesEnabled = dc/' dev.conf
fi

# update LimitDevAccess
sed -i 's/\(^LimitDevAccess = \)\(.*\)/\1'$LimitDevAccess'/g' dev.conf

for ((i = 0; i < $numC62xDevicesP; i++)); do
  ${CP} -f dev.conf /etc/c6xx_dev$i.conf
  [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/c6xx_dev$i.conf || \
  sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/c6xx_dev$i.conf
  grep -A 4 -B 3 'SHIM' /etc/c6xx_dev$i.conf
done

for ((i = 0; i < $numDh895xDevice; i++)); do
    ${CP} -f dev.conf /etc/dh895xcc_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/dh895xcc_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/dh895xcc_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/dh895xcc_dev$i.conf
done

for ((i = 0; i < $numC3xxxDevice; i++)); do
    ${CP} -f dev.conf /etc/c3xxx_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/c3xxx_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/c3xxx_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/c3xxx_dev$i.conf
done

for ((i = 0; i < $numC4xxxDevice; i++)); do
    ${CP} -f dev.conf /etc/c4xxx_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/c4xxx_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/c4xxx_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/c4xxx_dev$i.conf
done

for ((i = 0; i < $numC62xDevicesV; i++)); do
    ${CP} -f dev.conf /etc/c6xxvf_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/c6xxvf_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/c6xxvf_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/c6xxvf_dev$i.conf
done
for ((i = 0; i < $numE4xxxDevicesP; i++)); do
    ${CP} -f dev.conf /etc/4xxx_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/4xxx_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/4xxx_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/4xxx_dev$i.conf
done
for ((i = 0; i < $numE4xxxDevicesV; i++)); do
    ${CP} -f dev.conf /etc/4xxxvf_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/4xxxvf_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/4xxxvf_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/4xxxvf_dev$i.conf
done
for ((i = 0; i < $numE200xxDevicesP; i++)); do
    ${CP} -f dev.conf /etc/200xx_dev$i.conf
    [[ ! -z $SHARED_SHIM ]] && sed -i 's/^\[SSL\]$/\[SHIM'$i'\]/g' /etc/200xx_dev$i.conf || \
    sed -i 's/^\[SSL\]$/\[SHIM\]/g' /etc/200xx_dev$i.conf
    grep -A 4 -B 3 'SHIM' /etc/200xx_dev$i.conf
done
rm -f dev.conf

#install USDM
rmmod usdm_drv
MAX_HP=${MAX_HP:-$DEFAULT_MAX_HP}
MAX_HPP=${MAX_HPP:-$DEFAULT_MAX_HPP}
if [ $MAX_HP -ne 0 ]; then
  insmod ./usdm_drv.ko max_huge_pages=$MAX_HP max_huge_pages_per_process=$MAX_HPP
  echo $MAX_HP > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
else
  insmod ./usdm_drv.ko
  echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
fi
echo -e "\nHuge Page Info:" && cat /proc/meminfo | grep 'Huge'
echo

if [ $NUM_DEV != "0" ]; then
  service qat_service stop
  for ((i = 0; i < $NUM_DEV; i++)) do service qat_service start qat_dev$i ; done
else
  service qat_service restart
fi
service qat_service status
