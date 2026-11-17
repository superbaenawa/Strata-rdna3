#!/usr/bin/env bash
# Build the Strata-rdna3 engine for gfx1100 exactly as setup.py's build_engine_hip does, with user-space TheRock ROCm (default 10.2.0a20261022); BD=build dir, EXTRA_CMAKE/EXTRA_TARGETS optional
set -euo pipefail
R=${ROCM:-/AI/rocm/therock-10.2.0a20261022}; S=~/Strata-rdna3
export HIP_PLATFORM=amd HIP_COMPILER=clang HIP_RUNTIME=rocclr ROCM_PATH=$R HIP_PATH=$R PATH=$R/bin:$R/llvm/bin:$PATH LD_LIBRARY_PATH=$R/lib:${LD_LIBRARY_PATH:-}
cd $S
cmake -S . -B ${BD:-build-hip-10.2} -G Ninja -DCMAKE_BUILD_TYPE=Release -DSTRATA_ENABLE_HIP=ON -DSTRATA_ENABLE_CUDA=OFF -DSTRATA_BUILD_TESTS=OFF \
  -DSTRATA_PREFILL_MMQ=ON -DSTRATA_Q6K_EXPERTS=ON -DSTRATA_MMQ_KQUANTS=ON -DCMAKE_HIP_ARCHITECTURES=gfx1100 \
  -DCMAKE_HIP_COMPILER=$R/llvm/bin/clang++ -DCMAKE_HIP_COMPILER_ROCM_ROOT=$R -DCMAKE_PREFIX_PATH=$R \
  ${EXTRA_CMAKE:-} "-DCMAKE_HIP_FLAGS=${EXTRA_HIPFLAGS:-} --rocm-path=$R --rocm-device-lib-path=$R/lib/llvm/amdgcn/bitcode" \
  -DSTRATA_GGML_DIR=$S/third_party/llama.cpp -DSTRATA_ROCWMMA_INCLUDE_DIR=$S/third_party/rocwmma/library/include \
  > ${BD:-build-hip-10.2}.configure.log 2>&1 || { tail -30 ${BD:-build-hip-10.2}.configure.log; exit 1; }
grep -iE 'warn.*(hsa|NO_HSA)|rocwmma|STRATA_NO_HSA' ${BD:-build-hip-10.2}.configure.log | head -5 || true
time cmake --build ${BD:-build-hip-10.2} -j"$(nproc)" --target strata tune_hipblaslt ${EXTRA_TARGETS:-} > ${BD:-build-hip-10.2}.build.log 2>&1 || { grep -m5 ' error' ${BD:-build-hip-10.2}.build.log; tail -20 ${BD:-build-hip-10.2}.build.log; exit 1; }
ls -la ${BD:-build-hip-10.2}/strata && echo "BUILD OK"
