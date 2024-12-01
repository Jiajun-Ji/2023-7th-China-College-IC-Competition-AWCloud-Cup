#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "lite/api/paddle_place.h"
#include "lite/core/kernel.h"
#include "lite/core/op_lite.h"
#include "lite/core/op_registry.h"
#include "lite/core/subgraph/subgraph_bridge_registry.h"
#include "lite/core/subgraph/subgraph_engine_base.h"
#include "lite/core/tensor.h"
#include "lite/core/type_system.h"
#include "lite/core/types.h"
#include "lite/kernels/intel_fpga/bridges/graph.h"
#include "lite/utils/env.h"


namespace paddle {
namespace lite {
namespace kernels {
namespace intel_fpga {


class SubgraphEngine : public subgraph::SubgraphEngineBase {
 public:
  SubgraphEngine(KernelContext* ctx,
                 int block_idx,
                 const std::shared_ptr<const cpp::ProgramDesc>& program_desc,
                 Scope* exec_scope,
                 const std::vector<std::string>& input_names,
                 const std::vector<std::string>& output_names,
                 paddle::lite_api::PrecisionType type)
      : subgraph::SubgraphEngineBase(ctx,
                                     block_idx,
                                     program_desc,
                                     exec_scope,
                                     input_names,
                                     output_names),fp_type_(type)
                                     {}

 protected:
  bool BuildDeviceProgram() override {
  if (!origin_program_) {
    VLOG(4) << "Build intelfpga origin pragram.";
    BuildOriginProgram();
  }
  if (!device_programs_.count(origin_idims_)) {
    VLOG(4) << "Build intelfpga subgraph pragram.";
    int status = 0;
    auto graph = std::make_shared<subgraph::intel_fpga::Graph>();
    graph->set_input_names(input_names_);
    graph->set_output_names(output_names_);

    const auto& bridges = subgraph::SubgraphBridgeRegistry::Instance();
    const auto& insts = origin_program_->instructions(kRootBlockIdx);
    for (auto& inst : insts) {
      auto op = const_cast<OpLite*>(inst.op());
      CHECK(op);
      op->CheckShape();
      op->InferShape();
      std::string op_type = op->op_info()->Type();
      auto kernel = inst.kernel();
      status |=
          bridges.Select(op_type, TARGET(kIntelFPGA))(reinterpret_cast<void*>(graph.get()),
                                                const_cast<OpLite*>(op),
                                                const_cast<KernelBase*>(kernel));
      if (subgraph::CHECK_FAILED(status)) {
        return false;
      }
    }
    CHECK(device_programs_.count(origin_idims_) == 0);
    graph->BuildDeviceModel();
    device_programs_[origin_idims_] = graph;
  }
  return true;
}

bool LaunchDeviceProgram() override {
  auto GetCurrentUS = []() -> double {
    struct timeval time;
    gettimeofday(&time, NULL);
    return 1e+6 * time.tv_sec + time.tv_usec;
  };

  if (device_programs_.count(origin_idims_) == 0) {
    VLOG(4) << "Launch intelfpga origin pragram.";
    return LaunchOriginProgram();
  }

  VLOG(4) << "Launch intelfpga subgraph pragram.";
  return device_programs_[origin_idims_]->ExecuteDeviceGraph();
}
  bool InputShapeChanged() override{}
  paddle::lite_api::PrecisionType fp_type_;
public:
  std::map<std::vector<std::vector<int64_t>>, std::shared_ptr<subgraph::intel_fpga::Graph>>
      device_programs_;
};

class SubgraphCompute
    : public KernelLite<TARGET(kIntelFPGA), PRECISION(kInt8), DATALAYOUT(kNCHW)> {
 public:
  using param_t = operators::SubgraphParam;

  void PrepareForRun() override{
  auto& param = this->Param<param_t>();
  engine_.reset(new SubgraphEngine(this->ctx_.get(),
                                   param.block_idx,
                                   param.program_desc,
                                   param.exec_scope,
                                   param.input_data_names,
                                   param.output_data_names,
                                   this->precision()));
  CHECK(engine_);
}

void Run() override{
  CHECK(engine_);
  engine_->Run();
}
  virtual ~SubgraphCompute() = default;

 private:
  std::unique_ptr<SubgraphEngine> engine_;
};

}  // namespace apu
}  // namespace kernels
}  // namespace lite
}  // namespace paddle
