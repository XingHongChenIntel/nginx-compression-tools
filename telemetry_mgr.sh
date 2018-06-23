#!/bin/bash

function help() {
    echo "*****************************************************************"
    echo "* Usage: "
    echo "*     $0 action (data_level) (rp_num) (item) (bdf) (loop_times)"
    echo "* "
    echo "*     action:         start, stop or query "
    echo "*     data_level:     0: device level data "
    echo "*                     1: ring-pair level data "
    echo "*     rp_num:         get ring-pair data from ring-pair you "
    echo "*                     selected, like 4,6,7,9 default 0,1,2,3 ."
    echo "*     item:           select what data you want, if you want "
    echo "*                     pci_trans_cnt, set it to 0x80000000, "
    echo "*                     device level default 0xFE000000, ring-pair "
    echo "*                     level default 0x1E0. mask table as below: "
    echo "*                     Device level data "
    echo "*                     -------------------------------------------"
    echo "*                     | pci_trans_cnt              | 0x80000000 |"
    echo "*                     | max_rd_lat                 | 0x40000000 |"
    echo "*                     | rd_lat_acc_avg             | 0x20000000 |"
    echo "*                     | max_lat                    | 0x10000000 |"
    echo "*                     | lat_acc_avg                | 0x8000000  |"
    echo "*                     | bw_in                      | 0x4000000  |"
    echo "*                     | bw_out                     | 0x2000000  |"
    echo "*                     | at_page_req_lat_acc_avg    | 0x1000000  |"
    echo "*                     | at_trans_lat_acc_avg       | 0x800000   |"
    echo "*                     | at_max_tlb_used            | 0x400000   |"
    echo "*                     | util_cpr0                  | 0x200000   |"
    echo "*                     | util_dcpr0                 | 0x100000   |"
    echo "*                     | util_dcpr1                 | 0x80000    |"
    echo "*                     | util_dcpr2                 | 0x40000    |"
    echo "*                     | util_xlt0                  | 0x20000    |"
    echo "*                     | util_cph0                  | 0x10000    |"
    echo "*                     | util_cph1                  | 0x8000     |"
    echo "*                     | util_cph2                  | 0x4000     |"
    echo "*                     | util_cph3                  | 0x2000     |"
    echo "*                     | util_ath0                  | 0x1000     |"
    echo "*                     | util_ath1                  | 0x800      |"
    echo "*                     | util_ath2                  | 0x400      |"
    echo "*                     | util_ath3                  | 0x200      |"
    echo "*                     | util_ucs0                  | 0x100      |"
    echo "*                     | util_ucs1                  | 0x80       |"
    echo "*                     | util_pke0                  | 0x40       |"
    echo "*                     | util_pke1                  | 0x20       |"
    echo "*                     | util_pke2                  | 0x10       |"
    echo "*                     | util_pke3                  | 0x8        |"
    echo "*                     | util_pke4                  | 0x4        |"
    echo "*                     | util_pke5                  | 0x2        |"
    echo "*                     -------------------------------------------"
    echo "*                     ring-pair level data "
    echo "*                     -------------------------------------------"
    echo "*                     | pci_trans_cnt              | 0x100      |"
    echo "*                     | lat_acc_avg                | 0x80       |"
    echo "*                     | bw_in                      | 0x40       |"
    echo "*                     | bw_out                     | 0x20       |"
    echo "*                     | at_glob_devtlb_hit         | 0x10       |"
    echo "*                     | at_glob_devtlb_miss        | 0x8        |"
    echo "*                     | tl_at_payld_devtlb_hit     | 0x4        |"
    echo "*                     | tl_at_payld_devtlb_miss    | 0x2        |"
    echo "*                     -------------------------------------------"
    echo "*                     if you want util_dcpr0, util_dcpr1 and "
    echo "*                     util_dcpr2, set this option to 0x1C0000 ."
    echo "*     bdf:            domain, bus, device and function, you can "
    echo "*                     get data from one of all PCI devices, must "
    echo "*                     be physical function, like 0000:6b:00.0, "
    echo "*                     check all devices if omit. "
    echo "*     loop_times:     time of catching data, default 200, "
    echo "*                     2 times per second, no more than 7000 "
    echo "* "
    echo "* example: "
    echo "*     $0 start "
    echo "*     $0 stop"
    echo "*     $0 query 1 0,1,2,3"
    echo "*     $0 query 0 0x180 0000:6b:00.0 2400"
    echo "*     $0 query 1 4,5,6,7 0xE 0000:6b:00.0 2400"
    echo "*****************************************************************"
}

# Get total number of device directory
device_num=`lspci -d:4940 | wc -l`
# Get all bdf
all_dir=`lspci -d:4940 | awk -F " " '{print $1}' `
# Get kernel parameters
cmdl=`cat /proc/cmdline`

base_dir=/sys/bus/pci/devices
path=/
tmp_dir=/root/telemetry

datalevel=2
rp_num='0,1,2,3'
device_data_bit=0xFE000000
rp_data_bit=0x1E0
bdf=${all_dir}
loop_times=200

control_level_fail=0
device_level_fail=0
rp_level_fail=0

all_device_data="sample_cnt pci_trans_cnt max_rd_lat rd_lat_acc_avg max_lat lat_acc_avg bw_in bw_out at_page_req_lat_acc_avg at_trans_lat_acc_avg \
at_max_tlb_used util_cpr0 util_dcpr0 util_dcpr1 util_dcpr2 util_xlt0 util_cph0 util_cph1 util_cph2 util_cph3 util_ath0 util_ath1 util_ath2 \
util_ath3 util_ucs0 util_ucs1 util_pke0 util_pke1 util_pke2 util_pke3 util_pke4 util_pke5"


if [[ $# -lt 1 ]]
then
    echo "Wrong number of options."
    help
    exit 1
elif [[ $# -eq 2 ]]
then
    datalevel=$2
elif [[ $# -eq 3 ]]
then
    datalevel=$2
    if [[ ${datalevel} -eq 0 ]]
    then
        device_data_bit=$3
    elif [[ ${datalevel} -eq 1 ]]
    then
        rp_num=$3
    fi
elif [[ $# -eq 4 ]]
then
    datalevel=$2
    if [[ ${datalevel} -eq 0 ]]
    then
        device_data_bit=$3
        bdf=$4
        device_num=1
    elif [[ ${datalevel} -eq 1 ]]
    then
        rp_num=$3
        rp_data_bit=$4
    fi
elif [[ $# -eq 5 ]]
then
    datalevel=$2
    if [[ ${datalevel} -eq 0 ]]
    then
        device_data_bit=$3
        bdf=$4
        device_num=1
        loop_times=$5
    elif [[ ${datalevel} -eq 1 ]]
    then
        rp_num=$3
        rp_data_bit=$4
        bdf=$5
        device_num=1
    fi
elif [[ $# -eq 6 ]]
then
    datalevel=$2
    rp_num=$3
    rp_data_bit=$4
    bdf=$5
    device_num=1
    loop_times=$6
fi

if [[ $device_num -eq 0 ]]
then
    echo "No pci device directory on ${base_dir} "
    echo "Failed"
    exit 1
fi

function start_telemetry() {
    path=${base_dir}/$1/telemetry/control
    if [[ -e ${path} ]]
    then
        echo 1 > ${path}
    else
        control_level_fail=`expr ${control_level_fail} + 1`
        echo "No telemetry control file: ${path}."
    fi
}

function stop_telemetry() {
    path=${base_dir}/$1/telemetry/control
    if [[ -e ${path} ]]
    then
        echo 0 > ${path}
    else
        control_level_fail=`expr ${control_level_fail} + 1`
        echo "No telemetry control file: ${path}."
    fi
}

# Check device data item number
# if error, print device data and exit script
function check_device_data() {
    path=${base_dir}/$1/telemetry/device_data
    data_num=`cat ${path} | wc -l`
    all_data_names=`cat ${path} | awk -F " " '{print $1}'`

    if [[ ${data_num} -ne 32 ]]
    then
        echo "Error: device data number is incorrect."
        echo "File: ${path}"
        cat ${path}
        device_level_fail=`expr ${device_level_fail} + 1`
    else
        if [[ `echo ${all_data_names}` = ${all_device_data} ]]
        then
            echo "$1 count of device level data is ok."
        else
            echo "Error: device data mismatch."
            echo "File: ${path}"
            cat ${path}
            device_level_fail=`expr ${device_level_fail} + 1`
        fi
    fi
}

function check_device_zero() {
    data_list=`cat ${tmp_dir}/$1/telemetry/device_data | grep $2 | awk -F " " '{print $2}'`
    data_cnt=`cat ${tmp_dir}/$1/telemetry/device_data | grep $2 | wc -l`
    if [[ ${data_cnt} -eq 0 ]]
    then
        device_level_fail=`expr ${device_level_fail} + 1`
        echo "Error: $1 $2 miss"
    else
        for cnt in $(seq 1 ${data_cnt})
        do
            data=`echo ${data_list} | awk -F " " '{print $'$cnt'}'`
            if [[ ${data} -gt 0 ]]
            then
                break
            fi
            if [[ $cnt -eq ${data_cnt} ]]
            then
                device_level_fail=`expr ${device_level_fail} + 1`
                echo "Error: $1 $2 is 0"
            fi
        done
    fi
}

function collect_device_data() {
    for cnt in $(seq 1 ${loop_times})
    do
        for dev in $(seq 1 ${device_num})
        do
            bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
            if [[ ${bdf_dir} != *":"*":"*"."* ]]
            then
                bdf_dir="0000:${bdf_dir}"
            fi
            cat ${base_dir}/${bdf_dir}/telemetry/device_data >> ${tmp_dir}/${bdf_dir}/telemetry/device_data
        done
        sleep 0.5
    done
}

function verify_device_data() {
    for dev in $(seq 1 ${device_num})
    do
        bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
        if [[ ${bdf_dir} != *":"*":"*"."* ]]
        then
            bdf_dir="0000:${bdf_dir}"
        fi

        if [[ "device_data_bit&0x80000000" -eq 0x80000000 ]]
        then
            check_device_zero ${bdf_dir} 'pci_trans_cnt'
        fi
        if [[ "device_data_bit&0x40000000" -eq 0x40000000 ]]
        then
            check_device_zero ${bdf_dir} 'max_rd_lat'
        fi
        if [[ "device_data_bit&0x20000000" -eq 0x20000000 ]]
        then
            check_device_zero ${bdf_dir} 'rd_lat_acc_avg'
        fi
        if [[ "device_data_bit&0x10000000" -eq 0x10000000 ]]
        then
            check_device_zero ${bdf_dir} 'max_lat'
        fi
        if [[ "device_data_bit&0x8000000" -eq 0x8000000 ]]
        then
            check_device_zero ${bdf_dir} 'lat_acc_avg'
        fi
        if [[ "device_data_bit&0x4000000" -eq 0x4000000 ]]
        then
            check_device_zero ${bdf_dir} 'bw_in'
        fi
        if [[ "device_data_bit&0x2000000" -eq 0x2000000 ]]
        then
            check_device_zero ${bdf_dir} 'bw_out'
        fi
        if [[ "device_data_bit&0x1000000" -eq 0x1000000 ]]
        then
            check_device_zero ${bdf_dir} 'at_page_req_lat_acc_avg'
        fi
        if [[ "device_data_bit&0x800000" -eq 0x800000 ]]
        then
            check_device_zero ${bdf_dir} 'at_trans_lat_acc_avg'
        fi
        if [[ "device_data_bit&0x400000" -eq 0x400000 ]]
        then
            check_device_zero ${bdf_dir} 'at_max_tlb_used'
        fi
        if [[ "device_data_bit&0x200000" -eq 0x200000 ]]
        then
            check_device_zero ${bdf_dir} 'util_cpr0'
        fi
        if [[ "device_data_bit&0x100000" -eq 0x100000 ]]
        then
            check_device_zero ${bdf_dir} 'util_dcpr0'
        fi
        if [[ "device_data_bit&0x80000" -eq 0x80000 ]]
        then
            check_device_zero ${bdf_dir} 'util_dcpr1'
        fi
        if [[ "device_data_bit&0x40000" -eq 0x40000 ]]
        then
            check_device_zero ${bdf_dir} 'util_dcpr2'
        fi
        if [[ "device_data_bit&0x20000" -eq 0x20000 ]]
        then
            check_device_zero ${bdf_dir} 'util_xlt0'
        fi
        if [[ "device_data_bit&0x10000" -eq 0x10000 ]]
        then
            check_device_zero ${bdf_dir} 'util_cph0'
        fi
        if [[ "device_data_bit&0x8000" -eq 0x8000 ]]
        then
            check_device_zero ${bdf_dir} 'util_cph1'
        fi
        if [[ "device_data_bit&0x4000" -eq 0x4000 ]]
        then
            check_device_zero ${bdf_dir} 'util_cph2'
        fi
        if [[ "device_data_bit&0x2000" -eq 0x2000 ]]
        then
            check_device_zero ${bdf_dir} 'util_cph3'
        fi
        if [[ "device_data_bit&0x1000" -eq 0x1000 ]]
        then
            check_device_zero ${bdf_dir} 'util_ath0'
        fi
        if [[ "device_data_bit&0x800" -eq 0x800 ]]
        then
            check_device_zero ${bdf_dir} 'util_ath1'
        fi
        if [[ "device_data_bit&0x400" -eq 0x400 ]]
        then
            check_device_zero ${bdf_dir} 'util_ath2'
        fi
        if [[ "device_data_bit&0x200" -eq 0x200 ]]
        then
            check_device_zero ${bdf_dir} 'util_ath3'
        fi
        if [[ "device_data_bit&0x100" -eq 0x100 ]]
        then
            check_device_zero ${bdf_dir} 'util_ucs0'
        fi
        if [[ "device_data_bit&0x80" -eq 0x80 ]]
        then
            check_device_zero ${bdf_dir} 'util_ucs1'
        fi
        if [[ "device_data_bit&0x40" -eq 0x40 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke0'
        fi
        if [[ "device_data_bit&0x20" -eq 0x20 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke1'
        fi
        if [[ "device_data_bit&0x10" -eq 0x10 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke2'
        fi
        if [[ "device_data_bit&0x8" -eq 0x8 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke3'
        fi
        if [[ "device_data_bit&0x4" -eq 0x4 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke4'
        fi
        if [[ "device_data_bit&0x2" -eq 0x2 ]]
        then
            check_device_zero ${bdf_dir} 'util_pke5'
        fi
    done
}

function collect_rp_data() {
    for cnt in $(seq 1 ${loop_times})
    do
        for dev in $(seq 1 ${device_num})
        do
            bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
            if [[ ${bdf_dir} != *":"*":"*"."* ]]
            then
                bdf_dir="0000:${bdf_dir}"
            fi
            cat ${base_dir}/${bdf_dir}/telemetry/rp_A_data >> ${tmp_dir}/${bdf_dir}/telemetry/rp_A_data
            cat ${base_dir}/${bdf_dir}/telemetry/rp_B_data >> ${tmp_dir}/${bdf_dir}/telemetry/rp_B_data
            cat ${base_dir}/${bdf_dir}/telemetry/rp_C_data >> ${tmp_dir}/${bdf_dir}/telemetry/rp_C_data
            cat ${base_dir}/${bdf_dir}/telemetry/rp_D_data >> ${tmp_dir}/${bdf_dir}/telemetry/rp_D_data
        done
        sleep 0.5
    done
}


function check_rp_zero() {
    rp_A_data_list=`cat ${tmp_dir}/$1/telemetry/rp_A_data | grep -w $2 | uniq | awk -F " " '{print $2}'`
    rp_A_data_cnt=`cat ${tmp_dir}/$1/telemetry/rp_A_data | grep -w $2 | uniq | wc -l`
    rp_B_data_list=`cat ${tmp_dir}/$1/telemetry/rp_B_data | grep -w $2 | uniq | awk -F " " '{print $2}'`
    rp_B_data_cnt=`cat ${tmp_dir}/$1/telemetry/rp_B_data | grep -w $2 | uniq | wc -l`
    rp_C_data_list=`cat ${tmp_dir}/$1/telemetry/rp_C_data | grep -w $2 | uniq | awk -F " " '{print $2}'`
    rp_C_data_cnt=`cat ${tmp_dir}/$1/telemetry/rp_C_data | grep -w $2 | uniq | wc -l`
    rp_D_data_list=`cat ${tmp_dir}/$1/telemetry/rp_D_data | grep -w $2 | uniq | awk -F " " '{print $2}'`
    rp_D_data_cnt=`cat ${tmp_dir}/$1/telemetry/rp_D_data | grep -w $2 | uniq | wc -l`
    for cnt in $(seq 1 ${rp_A_data_cnt})
    do
        rpA_data=`echo ${rp_A_data_list} | awk -F " " '{print $'$cnt'}'`
        if [[ ${rpA_data} -gt 0 ]]
        then
            break
        fi

        if [[ $cnt -eq ${rp_A_data_cnt} ]]
        then
            rp_level_fail=`expr ${rp_level_fail} + 1`
            echo "Error: $1 rp_A_data $2 is 0"
        fi
    done

    for cnt in $(seq 1 ${rp_B_data_cnt})
    do
        rpB_data=`echo ${rp_B_data_list} | awk -F " " '{print $'$cnt'}'`
        if [[ ${rpB_data} -gt 0 ]]
        then
            break
        fi

        if [[ $cnt -eq ${rp_B_data_cnt} ]]
        then
            rp_level_fail=`expr ${rp_level_fail} + 1`
            echo "Error: $1 rp_B_data $2 is 0"
        fi
    done

    for cnt in $(seq 1 ${rp_C_data_cnt})
    do
        rpC_data=`echo ${rp_C_data_list} | awk -F " " '{print $'$cnt'}'`
        if [[ ${rpC_data} -gt 0 ]]
        then
            break
        fi

        if [[ $cnt -eq ${rp_C_data_cnt} ]]
        then
            rp_level_fail=`expr ${rp_level_fail} + 1`
            echo "Error: $1 rp_C_data $2 is 0"
        fi
    done

    for cnt in $(seq 1 ${rp_D_data_cnt})
    do
        rpD_data=`echo ${rp_D_data_list} | awk -F " " '{print $'$cnt'}'`
        if [[ ${rpD_data} -gt 0 ]]
        then
            break
        fi

        if [[ $cnt -eq ${rp_D_data_cnt} ]]
        then
            rp_level_fail=`expr ${rp_level_fail} + 1`
            echo "Error: $1 rp_D_data $2 is 0"
        fi
    done
}


function verify_rp_data() {
    for dev in $(seq 1 ${device_num})
    do
        bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
        if [[ ${bdf_dir} != *":"*":"*"."* ]]
        then
            bdf_dir="0000:${bdf_dir}"
        fi

        if [[ "rp_data_bit&0x100" -eq 0x100 ]]
        then
            check_rp_zero ${bdf_dir} 'pci_trans_cnt'
        fi
        if [[ "rp_data_bit&0x80" -eq 0x80 ]]
        then
            check_rp_zero ${bdf_dir} 'lat_acc_avg'
        fi
        if [[ "rp_data_bit&0x40" -eq 0x40 ]]
        then
            check_rp_zero ${bdf_dir} 'bw_in'
        fi
        if [[ "rp_data_bit&0x20" -eq 0x20 ]]
        then
            check_rp_zero ${bdf_dir} 'bw_out'
        fi
        if [[ "rp_data_bit&0x10" -eq 0x10 ]]
        then
            check_rp_zero ${bdf_dir} 'at_glob_devtlb_hit'
        fi
        if [[ "rp_data_bit&0x8" -eq 0x8 ]]
        then
            check_rp_zero ${bdf_dir} 'at_glob_devtlb_miss'
        fi
        if [[ "rp_data_bit&0x4" -eq 0x4 ]]
        then
            check_rp_zero ${bdf_dir} 'tl_at_payld_devtlb_hit'
        fi
        if [[ "rp_data_bit&0x2" -eq 0x2 ]]
        then
            check_rp_zero ${bdf_dir} 'tl_at_payld_devtlb_miss'
        fi
    done
}

case $1 in
    "start"|"Start")
        for dev in $(seq 1 ${device_num})
        do
            bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
            if [[ ${bdf_dir} != *":"*":"*"."* ]]
            then
                bdf_dir="0000:${bdf_dir}"
            fi
            start_telemetry ${bdf_dir}
        done
        if [[ ${control_level_fail} -eq 0 ]]
        then
            echo "control update success"
        else
            echo "control update failed"
        fi
    ;;
    "stop"|"Stop")
        for dev in $(seq 1 ${device_num})
        do
            bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
            if [[ ${bdf_dir} != *":"*":"*"."* ]]
            then
                bdf_dir="0000:${bdf_dir}"
            fi
            stop_telemetry ${bdf_dir}
        done
        if [[ ${control_level_fail} -eq 0 ]]
        then
            echo "control update success"
        else
            echo "control update failed"
        fi
    ;;
    "query"|"Query")
        if [[ ${datalevel} -eq 0 ]]
        then
            for dev in $(seq 1 ${device_num})
            do
                bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
                if [[ ${bdf_dir} != *":"*":"*"."* ]]
                then
                    bdf_dir="0000:${bdf_dir}"
                fi
                check_device_data ${bdf_dir}
                data_path=${tmp_dir}/${bdf_dir}/telemetry
                mkdir -p ${data_path}
            done
            collect_device_data
            verify_device_data
            if [[ ${device_level_fail} -eq 0 ]]
            then
                echo "Device Data Query Success"
            else
                echo "Device Data Query Fail"
            fi
        elif [[ ${datalevel} -eq 1 ]]
        then
            for dev in $(seq 1 ${device_num})
            do
                bdf_dir=`echo ${bdf} | awk -F " " '{print $'$dev'}'`
                if [[ ${bdf_dir} != *":"*":"*"."* ]]
                then
                    bdf_dir="0000:${bdf_dir}"
                fi
                data_path=${tmp_dir}/${bdf_dir}/telemetry
                mkdir -p ${data_path}
                if [[ ${rp_num} != '0,1,2,3' ]]
                then
                    rpA=`cat ${base_dir}/${bdf_dir}/telemetry/rp_A_data | grep rp_num | awk -F " " '{print $NF}'`
                    rpB=`cat ${base_dir}/${bdf_dir}/telemetry/rp_B_data | grep rp_num | awk -F " " '{print $NF}'`
                    rpC=`cat ${base_dir}/${bdf_dir}/telemetry/rp_C_data | grep rp_num | awk -F " " '{print $NF}'`
                    rpD=`cat ${base_dir}/${bdf_dir}/telemetry/rp_D_data | grep rp_num | awk -F " " '{print $NF}'`

                    rp_A_num=`echo ${rp_num} | awk -F "," '{print $1}'`
                    if [[ ${rp_A_num} -eq ${rpA} || ${rp_A_num} -eq ${rpB} || ${rp_A_num} -eq ${rpC} || ${rp_A_num} -eq ${rpD} ]]
                    then
                        echo "rp_${rp_A_num} is default ring-pair."
                    else
                        echo ${rp_A_num} > ${base_dir}/${bdf_dir}/telemetry/rp_A_data
                    fi

                    rp_B_num=`echo ${rp_num} | awk -F "," '{print $2}'`
                    if [[ ${rp_B_num} -eq ${rpA} || ${rp_B_num} -eq ${rpB} || ${rp_B_num} -eq ${rpC} || ${rp_B_num} -eq ${rpD} ]]
                    then
                        echo "rp_${rp_B_num} is default ring-pair."
                    else
                        echo ${rp_B_num} > ${base_dir}/${bdf_dir}/telemetry/rp_B_data
                    fi

                    rp_C_num=`echo ${rp_num} | awk -F "," '{print $3}'`
                    if [[ ${rp_C_num} -eq ${rpA} || ${rp_C_num} -eq ${rpB} || ${rp_C_num} -eq ${rpC} || ${rp_C_num} -eq ${rpD} ]]
                    then
                        echo "rp_${rp_C_num} is default ring-pair."
                    else
                        echo ${rp_C_num} > ${base_dir}/${bdf_dir}/telemetry/rp_C_data
                    fi

                    rp_D_num=`echo ${rp_num} | awk -F "," '{print $4}'`
                    if [[ ${rp_D_num} -eq ${rpA} || ${rp_D_num} -eq ${rpB} || ${rp_D_num} -eq ${rpC} || ${rp_D_num} -eq ${rpD} ]]
                    then
                        echo "rp_${rp_D_num} is default ring-pair."
                    else
                        echo ${rp_D_num} > ${base_dir}/${bdf_dir}/telemetry/rp_D_data
                    fi
                fi
            done
            collect_rp_data
            verify_rp_data
            if [[ ${rp_level_fail} -eq 0 ]]
            then
                echo "Ring-Pair Data Query Success"
            else
                echo "Ring-Pair Data Query Fail"
            fi
        else
            echo "Wrong option: ${datalevel}"
        fi
    ;;
    *)
        echo "Unknow option."
        help
        exit 1
    ;;
esac

yes | rm -rf ${tmp_dir}