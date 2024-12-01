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
#include "lite/core/optimizer/mir/pass_manager.h"

namespace paddle {
namespace lite {
namespace mir {

/*
 * Correct the place of the variables in the SSAGrpah, it will inference the
 * variables' place by the kernels outputs them.
 */
class IntelFPGACalibPlaceCorrectPass : public ProgramPass {
 public:
  void Apply(const std::unique_ptr<SSAGraph>& graph) override;
};

class IntelFPGAKernelPlaceCorrectPass : public ProgramPass {
 public:
  void Apply(const std::unique_ptr<SSAGraph>& graph) override;

 private:
  void CorrectArgumentPlace(SSAGraph* graph) {
    std::map<std::string, Node*> cast_nodes;
    VLOG(3) << "param-type-registry:\n" << ParamTypeRegistry::Global();
    for (auto& x : graph->StmtTopologicalOrder()) {
      auto& inst = x->AsStmt();
      // deal with inputs
      VLOG(4) << "checking op " << inst.op_info()->Repr();

      auto get_argname = [&](
          const std::string& node_name,
          const std::map<std::string, std::vector<std::string>>& argname_map)
          -> std::string {
            for (auto& ele : argname_map) {
              auto it =
                  std::find(ele.second.begin(), ele.second.end(), node_name);
              if (it != ele.second.end()) return ele.first;
            }
            return "";
          };

      auto in = x->inlinks.front();
      if (!in) {
        continue;
      }
      auto out = x->outlinks.front();

      std::string node_name = out->AsArg().name;
      auto op_type = inst.op_type();

      if(op_type == "conv2d" || op_type == "depthwise_conv2d" ||
         op_type == "fusion_elementwise_add_activation" ||
         op_type == "pool2d" ||
         op_type == "elementwise_add") {
        bool has_quantized_op_after = false;
        for(auto* out_n: x->outlinks) {
          CHECK(out_n->IsArg());
          for(auto* tmp_op: out_n->outlinks) {
            CHECK(tmp_op->IsStmt());
            auto* tmp_op_info = tmp_op->AsStmt().op_info();
            if(tmp_op_info->HasAttr("forced_scale")) {
              has_quantized_op_after = true;
              auto out_node_name = out_n->arg()->name;
              std::vector<float> scale_v = {0.f};
              auto scale_name = out_node_name + "_forced_scale";
              if (tmp_op_info->HasAttr(scale_name)) {
                scale_v[0] = tmp_op_info->GetAttr<float>(scale_name);
              } else {
                scale_v[0] = tmp_op_info->GetAttr<float>("forced_scale");
              }
              inst.mutable_op_info()->SetOutputScale(
                out_node_name,
                scale_v);
              tmp_op->AsStmt().mutable_op_info()->SetInputScale(
                out_node_name,
                scale_v);
              break;;
            } else if(tmp_op_info->HasAttr("enable_int8")) {
              auto out_node_name = out_n->arg()->name;
              std::vector<float> scale_v;
              scale_v = tmp_op_info->GetInputScale(out_n->arg()->name);
              // scale_v[0] = tmp_op_info->GetAttr<float>("forced_scale");
              inst.mutable_op_info()->SetOutputScale(
                out_node_name,
                scale_v);
              break;
            }
          }
        }
      }

      // Fix bug that concat op after elementwise_add would not't insert calib.
      //        elementwise_add -> concat(with forced_scale attribute) ====》
      //        elementwise_add-> calib -> concat
      if(inst.op_info()->HasAttr("forced_scale") &&
         op_type == "concat") {
         std::cout << "Insert calib op before concat.\n";
         for(auto* in_n: x->inlinks) {
           CHECK(in_n->IsArg());
           std::vector<float> scale_v = {0.f};
           auto in_node_name = in_n->arg()->name;
           auto scale_name = in_node_name + "_forced_scale";
           if (inst.op_info()->HasAttr(scale_name)) {
             scale_v[0] = inst.op_info()->GetAttr<float>(scale_name);
           } else {
             scale_v[0] = inst.op_info()->GetAttr<float>("forced_scale");
           }
           inst.mutable_op_info()->SetInputScale(
             in_node_name,
             scale_v);
         }
      }
    }
  }

  // Update me's kUnk fields by other's fields.
  void UpdateTarget(mir::Node::Stmt& inst, TargetType new_target) {  // NOLINT
    auto new_place = inst.place();

    new_place.target = new_target;
    if (new_target == TargetType::kARM) {
      new_place.precision = PrecisionType::kFloat;
      new_place.layout = DataLayoutType::kNCHW;
    }

    if (new_target == TargetType::kIntelFPGA) {
      new_place.precision = PrecisionType::kInt8;
      new_place.layout = DataLayoutType::kNCHW;
    }

    std::vector<Place> places;
    places.push_back(new_place);
    inst.ResetKernels(places);
  }

  void UpdateTensor(mir::Node::Stmt& inst,  // NOLINT
                    Node* in,
                    Node* out,
                    TargetType new_target = TargetType::kUnk) {
    auto get_argname = [&](
        const std::string& node_name,
        const std::map<std::string, std::vector<std::string>>& argname_map)
        -> std::string {
          for (auto& ele : argname_map) {
            auto it =
                std::find(ele.second.begin(), ele.second.end(), node_name);
            if (it != ele.second.end()) return ele.first;
          }
          return "";
        };
    std::string in_name =
        get_argname(in->AsArg().name, inst.op_info()->inputs());

    auto type = inst.picked_kernel().GetInputDeclType(in_name);
    auto tmp_ptype = in->AsArg().type->precision();
    auto tmp_target = type->target();
    auto tmp_layout = type->layout();

    if (new_target == TargetType::kARM) {
      tmp_target = TargetType::kARM;
      tmp_ptype = PrecisionType::kFloat;
      tmp_layout = DataLayoutType::kNCHW;
    }

    if (new_target == TargetType::kIntelFPGA) {
      tmp_target = TargetType::kARM;
      tmp_ptype = PrecisionType::kInt8;
      tmp_layout = DataLayoutType::kNCHW;
    }

    out->AsArg().type =
        LiteType::GetTensorTy(tmp_target, tmp_ptype, tmp_layout);
  }
};

}  // namespace mir
}  // namespace lite
}  // namespace paddle
