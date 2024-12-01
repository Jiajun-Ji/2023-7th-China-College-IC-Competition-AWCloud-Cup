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

#pragma once
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "lite/core/optimizer/mir/pass.h"
#include "lite/core/target_wrapper.h"
#include "lite/core/optimizer/mir/type_precision_cast_pass.h"
#include "lite/core/optimizer/mir/pass_manager.h"

namespace paddle {
namespace lite {
namespace mir {

class IntelFPGAInsertCalibPass : public ProgramPass {
 public:
  void Apply(const std::unique_ptr<SSAGraph>& graph) override;

 private:
  void CorrectArgumentPlace(SSAGraph* graph) {
    std::map<std::string, Node*> cast_nodes;
    VLOG(3) << "param-type-registry:\n" << ParamTypeRegistry::Global();
    for (auto& x : graph->StmtTopologicalOrder()) {
      auto& inst = x->AsStmt();
      // deal with inputs
      auto in = x->inlinks.front();
      if (!in) {
        continue;
      }
      auto op_type = inst.op_type();

      // Aadd enble_int8 attrr to subgraph op.
      if (op_type == "subgraph") {
        //x->stmt()->mutable_op_info()->SetAttr("enable_int8", true);
        for(auto* out_n: x->outlinks) {
          CHECK(out_n->IsArg());
          for(auto* tmp_op: out_n->outlinks) {
            //CHECK(tmp_op->IsStmt());
            if (!tmp_op->IsStmt()) {
              continue;
            }
            auto* tmp_op_info = tmp_op->AsStmt().op_info();
            if(tmp_op_info->HasAttr("forced_scale")) {
              auto to = LiteType::GetTensorTy(
                  TargetType::kARM, PrecisionType::kFloat, DataLayoutType::kNCHW);
              auto type_precision_pass =
                  dynamic_cast<PrecisionCastPass*>(PassManager::Global().LookUp("type_precision_cast_pass"));
              type_precision_pass->AddCastInst(*out_n->AsArg().type,
                         *to,
                         out_n,
                         graph,
                         tmp_op,
                         &cast_nodes,
                         graph->valid_places());
            }
          }
        }
      }
    }
  }
};

}  // namespace mir
}  // namespace lite
}  // namespace paddle
