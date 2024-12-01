// Copyright (c) 2019 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "lite/core/optimizer/mir/intel_fpga_kernel_place_correct_pass.h"
#include <memory>
#include "lite/core/optimizer/mir/pass_registry.h"

namespace paddle {
namespace lite {
namespace mir {

void IntelFPGAKernelPlaceCorrectPass::Apply(const std::unique_ptr<SSAGraph> &graph) {
  std::cout<<"IntelFPGAKernelPlaceCorrectPass\n";
  CorrectArgumentPlace(graph.get());
}
void IntelFPGACalibPlaceCorrectPass::Apply(const std::unique_ptr<SSAGraph>& graph){
  return;
  for (auto& x : graph->StmtTopologicalOrder()) {
      auto& inst = x->AsStmt();
      auto op_type = inst.op_type();
      if(op_type == "calib"){
        auto in = x->inlinks.front();
        CHECK(in->IsArg());
        auto from_type = in->AsArg().type;
        if(from_type->precision()!=PrecisionType::kInt8) continue;
        for(auto& kernel : inst.kernels())
        std::cout<<"calib kernel old:"<<TargetToStr(kernel->target()).c_str()<<"\t"<<
                                    PrecisionToStr(kernel->precision()).c_str()<<"\t"<<"\n";
        Place new_place(TargetType::kIntelFPGA,PrecisionType::kInt8,DataLayoutType::kNCHW);
        std::vector<Place> places;
        places.push_back(new_place);
        inst.ResetKernels(places);
        for (auto& kernel : x->AsStmt().kernels()) {
          VLOG(4) << "kernel info: " << kernel->name();
          x->AsStmt().op()->AttachKernel(kernel.get());
        }
        for(auto& kernel : inst.kernels())
        std::cout<<"calib kernel new:"<<TargetToStr(kernel->target()).c_str()<<"\t"<<
                                    PrecisionToStr(kernel->precision()).c_str()<<"\t"<<"\n";
        std::cout<<"end\n";
    }
  }
}
}  // namespace mir
}  // namespace lite
}  // namespace paddle

REGISTER_MIR_PASS(intel_fpga_kernel_place_correct_pass,
                  paddle::lite::mir::IntelFPGAKernelPlaceCorrectPass)
    .BindTargets({TARGET(kIntelFPGA)});
REGISTER_MIR_PASS(intel_fpga_calib_place_correct_pass,
                  paddle::lite::mir::IntelFPGACalibPlaceCorrectPass)
    .BindTargets({TARGET(kIntelFPGA)});
