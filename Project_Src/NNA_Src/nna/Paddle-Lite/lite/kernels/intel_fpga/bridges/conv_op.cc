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

#include "lite/operators/conv_op.h"
#include<intelfpga.h>
#include "lite/kernels/intel_fpga/bridges/graph.h"
#include "lite/core/subgraph/subgraph_bridge_registry.h"

namespace paddle {
namespace lite {
namespace subgraph {
namespace intel_fpga {

int ConvConverter(void *ctx, OpLite *op, KernelBase *kernel) {
    VLOG(4) << "Converting conv2d op for intelfpga.";
    CHECK(ctx != nullptr);
    CHECK(op != nullptr);
    auto graph = static_cast<Graph*>(ctx);

    operators::ConvParam& param = kernel->Param<operators::ConvParam>();
    std::string op_type = op->op_info()->Type();
    auto op_info = op->op_info();
    auto scope = op->scope();

    auto input_name = op_info->Input("Input").front();
    auto filter_name = op_info->Input("Filter").front();
    auto output_name = op_info->Output("Output").front();
    auto output = scope->FindMutableTensor(output_name);
    auto w_dims = param.filter->dims();
    auto i_dims = param.x->dims();
    auto o_dims = param.output->dims();

    Node* node = new Node();
    node->name_ = output_name;
    // Create node's device param.
    FpgaConvParam* device_param = new FpgaConvParam();
    node->node_param_ = dynamic_cast<NodeParam*>(device_param);
    node->is_output = graph->IsOutput(output_name);
    node->is_input = graph->IsInput(input_name);
    node->op_type_ = (param.groups==1)?INTELFPGA_Conv2D:INTELFPGA_DW_Conv2D;

    // Find this node's parent according to input tensor.
    if(graph->GetNodeByTensorName(input_name)) {
        node->parent_vec_.push_back(graph->GetNodeByTensorName(input_name));
        int byte_offset =
          FpgaWord2ByteOffset(node->parent_vec_[0]->op_type_,
              FpgaGetOutputOffset(node->parent_vec_[0]));
      device_param->param.input_offset = FpgaByte2WordOffset(node->op_type_, byte_offset);
    } else {
      node->parent_vec_.push_back(nullptr);
      device_output_config config = FpgaMemMalloc(node->op_type_,
          device_param->d_ia, i_dims[1], i_dims[2], i_dims[3]);
      device_param->param.input_offset = config.output_offset;
    }
    if (graph->getGraphRootNode() == nullptr) {
      graph->setGraphRootNode(node);
    }

    // Malloc output and set offset.
    device_output_config config = FpgaMemMalloc(node->op_type_,
        device_param->d_oa, o_dims[1], o_dims[2], o_dims[3]);
    device_param->param.output_offset = config.output_offset;
    device_param->param.output_size = config.output_size;
    VLOG(4) << "output_offset: " << device_param->param.output_offset;
    VLOG(4) << "output_siez: " << device_param->param.output_size;

    // Put this node's output tensor in map.
    graph->setTensor2Node(output_name, node);

    // Let predecessor node in topological order link to this node.
    auto pre_node = graph->getGraphTailNode();
    if(pre_node) {
      pre_node->next_ = node;
    }

    graph->setGraphTailNode(node);
    node->next_= nullptr;

    device_param->ia = param.x->mutable_data<int8_t>();
    device_param->oa = param.output->mutable_data<int8_t>();
    device_param->ka = param.filter->mutable_data<int8_t>();
    float *ba = param.bias ? param.bias->mutable_data<float>() : nullptr;
    float *scale=param.weight_scale.data() ? param.weight_scale.data() : nullptr;

    // Fill fpga_param.
    int group = param.groups;
    auto paddings = *param.paddings;
    auto dilations = *param.dilations;
    // CHECK_EQ(dilations[0], 1);
    uint32_t at_;

    switch (param.activation_param.active_type) {
        case lite_api::ActivationType::kRelu:
        at_ = INTELFPGA_ACT_RELU;
        break;
        case lite_api::ActivationType::kRelu6:
        at_ = INTELFPGA_ACT_RELU6;
        break;
        case lite_api::ActivationType::kLeakyRelu:
        at_ = INTELFPGA_ACT_LEAKYRELU;
        device_param->param.lr = param.activation_param.Leaky_relu_alpha;
        break;
        default:
        at_ = INTELFPGA_ACT_NONE;
        break;
    }
    //init scale
    device_param->scale = new float[2*o_dims[1]];
    device_param->param.input_scale = param.input_scale;
    device_param->param.output_scale = param.output_scale;

    VLOG(4) << "input scale: " << param.input_scale;
    VLOG(4) << "output scale: " << param.output_scale;
    if(scale){
        for(int i=0;i<o_dims[1];i++)
        {
            device_param->scale[i]=scale[i];
        }
    }
    if(ba){
        for(int i=0;i<o_dims[1];i++)
        {
            device_param->scale[o_dims[1]+i]=ba[i]/param.output_scale;
        }
    }else{
        for(int i=0;i<o_dims[1];i++)
        {
            device_param->scale[o_dims[1]+i]=0;
        }
    }
    
    //ignore batch dimension TODO
    device_param->param.scale_offset = 0;
    device_param->d_ka = nullptr;
    device_param->param.in_c=i_dims[1];
    device_param->param.in_h=i_dims[2];
    device_param->param.in_w=i_dims[3];
    device_param->param.output_c=o_dims[1];
    device_param->param.output_h=o_dims[2];
    device_param->param.output_w=o_dims[3];
    device_param->param.in_pad=paddings[0];
    device_param->param.kernel=w_dims[2];
    device_param->param.stride=param.strides[0];
    device_param->param.relu=at_;
    device_param->param.dilation=dilations[0];

    device_param->param.type=(param.groups==1)?INTELFPGA_Conv2D:INTELFPGA_DW_Conv2D;
    if(param.groups==1){
        struct device_weight_config config= conv2d_weight_reorganize(
            device_param->ka,
            (int8_t**)(&(device_param->d_ka)),
            w_dims[0],
            w_dims[1],
            w_dims[2],
            w_dims[3],
            filter_name.c_str());
        device_param->param.weight_size = config.weight_size;
        device_param->param.weight_offset = config.weight_offset;
    }
    else{
        struct device_weight_config config = dw_conv2d_weight_reorganize(device_param->ka,(int8_t**)(&(device_param->d_ka)),w_dims[0],w_dims[2],w_dims[3]);
        device_param->param.weight_size = config.weight_size;
        device_param->param.weight_offset = config.weight_offset;
    }
    VLOG(4) << "Converting conv2d op for intelfpga end.";
  return SUCCESS;
}

}  // namespace imagination_nna
}  // namespace subgraph
}  // namespace lite
}  // namespace paddle

REGISTER_SUBGRAPH_BRIDGE(
    conv2d,
    kIntelFPGA,
    paddle::lite::subgraph::intel_fpga::ConvConverter);

REGISTER_SUBGRAPH_BRIDGE(
    depthwise_conv2d,
    kIntelFPGA,
    paddle::lite::subgraph::intel_fpga::ConvConverter);
