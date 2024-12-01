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
#include <intelfpga.h>

#include "lite/utils/env.h"
#include "lite/utils/log/logging.h"
#include "lite/utils/macros.h"

namespace paddle {
namespace lite {
namespace subgraph {
namespace intel_fpga {

using Node = DeviceGraphNode;
class Graph {
 public:
  // bool ExecuteDeviceGraph();
  bool ExecuteDeviceGraph() {
    return intelfpga_subgraph(root_);
  }
  // For device graph, each node's output should be set.
  // And for input and output node, allocate space for device input and output.
  bool BuildDeviceModel();

  // The node in subgraph whose output ref count is larger than 1 is constricted
  // to no more than 10. Also, the input, filter and output size should be check.
  bool DeviceModelValidCheck();

  ~Graph() {
    auto node = root_;
     // Delete root node's input space which size is extent_input_size.
    VLOG(4) << "Release intelfpga graph.";

    while(node) {
      // Delete device_param_ and it's children.
       if (node->node_param_) {
         delete node->node_param_;
         node->node_param_ = nullptr;
       }
      // Delete node itself.
      auto node_delete = node;
      node = node->next_;
      delete node_delete;
    }
    VLOG(4) << "Release intelfpga graph done.";
  }

  void set_input_names(const std::vector<std::string> input_names) {
    input_names_ = input_names;
  }

  bool IsInput(const std::string& name) {
    for (int i = 0; i < input_names_.size(); i++) {
      if (input_names_[i] == name) return true;
    }
    return false;
  }

  bool IsOutput(const std::string& name) {
    for (int i = 0; i < output_names_.size(); i++) {
      if (output_names_[i] == name) return true;
    }
    return false;
  }

  void set_output_names(const std::vector<std::string> output_names) {
    output_names_ = output_names;
  }

  void setTensor2Node(std::string name, Node* node) {
    VLOG(4) << "node name: " << name;
    if(tensor2node_.find(name) == tensor2node_.end()) {
      tensor2node_[name] = node;
    } else {
      std::cout << "[IntelFPGA] Node" << name << " is redefined.";
    }
  }

  Node* GetNodeByTensorName(std::string name) {
    if(tensor2node_.find(name) != tensor2node_.end()) {
      return tensor2node_[name];
    } else {
      return nullptr;
    }
  }

  Node* getGraphRootNode() {
    return root_;
  }
  Node* getGraphTailNode() {
    return tail_;
  }

  bool SetScale(std::string scale_name, float scale) {
    if (scale_m_.count(scale_name) > 0) {
      //CHECK_EQ(scale, scale_m_[scale_name]);
      return false;
    }
    scale_m_.insert({scale_name, scale});
    return true;
  }

  void setGraphRootNode(Node* node) {
    root_ = node;
  }
  void setGraphTailNode(Node* node) {
    tail_ = node;
  }

 private:
  Node* root_{nullptr};
  Node* tail_{nullptr};
  std::vector<std::string> input_names_;
  std::vector<std::string> output_names_;
  // std::map<std::string, int> tensor_ref_count_; // Referencing count of tensor.
  std::map<std::string, Node*> tensor2node_; // Map tensor to node which output this tensor.
  std::map<std::string, float> scale_m_;
  // Subgraph input.
};

}  // namespace apu
}  // namespace subgraph
}  // namespace lite
}  // namespace paddle
