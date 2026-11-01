#!/bin/bash
# pad2 (05e458f-amended head, tail modes 1/2): test binary into /root/pad/pad2 (shared /root/tgt; post's spirv build is done), then the CUDA dump + ptxas for mode 2.
L=/root/pad
/root/build.sh padsrc2 pad2 gpu || exit 1
echo PAD2_DONE $(date -u +%T) > $L/pad2.done
