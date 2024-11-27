#!/bin/bash

echo "** Previous cpu governor"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

sudo cpupower frequency-set -g performance

echo "** Current cpu governor"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor