# copyright (c) 2020 PaddlePaddle Authors. All Rights Reserve.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import paddle.nn as nn
import paddle.nn.functional as F
from paddle import ParamAttr
from paddle.regularizer import L2Decay
from paddle.nn.initializer import KaimingNormal
from ppdet.core.workspace import register, serializable
from numbers import Integral
from ..shape_spec import ShapeSpec

__all__ = ['MobileNet']

import  numpy as np
prune_ratios=np.array([0.75,0.8125,0.625,0.5,
                   0.5,0.5625,0.5625,0.625,
                   0.4375,0.3125,0.6875,0.875,  
                   0.875,0.875,0.9375,0.9375],dtype=float)
prune_ratios=1-prune_ratios
output_prune_ratios=np.array([0.5,0.5,0.5,0.5,0.5,0.5],dtype=float)
# output_prune_ratios=np.array([1.,1.,1.,1.,1.,1.,1.],dtype=float)

class ConvBNLayer(nn.Layer):
    def __init__(self,
                 in_channels,
                 out_channels,
                 kernel_size,
                 stride,
                 padding,
                 num_groups=1,
                 act='relu',
                 conv_lr=1.,
                 conv_decay=0.,
                 norm_decay=0.,
                 norm_type='bn',
                 name=None):
        super(ConvBNLayer, self).__init__()
        self.act = act
        self._conv = nn.Conv2D(
            in_channels,
            out_channels,
            kernel_size=kernel_size,
            stride=stride,
            padding=padding,
            groups=num_groups,
            weight_attr=ParamAttr(
                learning_rate=conv_lr,
                initializer=KaimingNormal(),
                regularizer=L2Decay(conv_decay)),
            bias_attr=False)

        param_attr = ParamAttr(regularizer=L2Decay(norm_decay))
        bias_attr = ParamAttr(regularizer=L2Decay(norm_decay))
        if norm_type == 'sync_bn':
            self._batch_norm = nn.SyncBatchNorm(
                out_channels, weight_attr=param_attr, bias_attr=bias_attr)
        else:
            self._batch_norm = nn.BatchNorm(
                out_channels,
                act=None,
                param_attr=param_attr,
                bias_attr=bias_attr,
                use_global_stats=False)

    def forward(self, x):
        x = self._conv(x)
        x = self._batch_norm(x)
        if self.act == "relu":
            x = F.relu(x)
        elif self.act == "relu6":
            x = F.relu6(x)
        return x


class DepthwiseSeparable(nn.Layer):
    def __init__(self,
                 in_channels,
                 out_channels1,
                 out_channels2,
                 num_groups,
                 stride,
                 scale,
                 conv_lr=1.,
                 conv_decay=0.,
                 norm_decay=0.,
                 norm_type='bn',
                 name=None):
        super(DepthwiseSeparable, self).__init__()

        self._depthwise_conv = ConvBNLayer(
            in_channels,
            int(out_channels1 * scale),
            kernel_size=3,
            stride=stride,
            padding=1,
            num_groups=int(num_groups * scale),
            conv_lr=conv_lr,
            conv_decay=conv_decay,
            norm_decay=norm_decay,
            norm_type=norm_type,
            name=name + "_dw")

        self._pointwise_conv = ConvBNLayer(
            int(out_channels1 * scale),
            int(out_channels2 * scale),
            kernel_size=1,
            stride=1,
            padding=0,
            conv_lr=conv_lr,
            conv_decay=conv_decay,
            norm_decay=norm_decay,
            norm_type=norm_type,
            name=name + "_sep")

    def forward(self, x):
        x = self._depthwise_conv(x)
        x = self._pointwise_conv(x)
        return x


class ExtraBlock(nn.Layer):
    def __init__(self,
                 in_channels,
                 out_channels1,
                 out_channels2,
                 num_groups=1,
                 stride=2,
                 conv_lr=1.,
                 conv_decay=0.,
                 norm_decay=0.,
                 norm_type='bn',
                 name=None):
        super(ExtraBlock, self).__init__()

        self.pointwise_conv = ConvBNLayer(
            in_channels,
            int(out_channels1),
            kernel_size=1,
            stride=1,
            padding=0,
            num_groups=int(num_groups),
            act='relu6',
            conv_lr=conv_lr,
            conv_decay=conv_decay,
            norm_decay=norm_decay,
            norm_type=norm_type,
            name=name + "_extra1")

        self.normal_conv = ConvBNLayer(
            int(out_channels1),
            int(out_channels2),
            kernel_size=3,
            stride=stride,
            padding=1,
            num_groups=int(num_groups),
            act='relu6',
            conv_lr=conv_lr,
            conv_decay=conv_decay,
            norm_decay=norm_decay,
            norm_type=norm_type,
            name=name + "_extra2")

    def forward(self, x):
        x = self.pointwise_conv(x)
        x = self.normal_conv(x)
        return x


@register
@serializable
class MobileNet(nn.Layer):
    __shared__ = ['norm_type']

    def __init__(self,
                 norm_type='bn',
                 norm_decay=0.,
                 conv_decay=0.,
                 scale=1,
                 conv_learning_rate=1.0,
                 feature_maps=[4, 6, 13],
                 with_extra_blocks=False,
                 extra_block_filters=[[256, 512], [128, 256], [128, 256],
                                      [64, 128]]):
        super(MobileNet, self).__init__()
        if isinstance(feature_maps, Integral):
            feature_maps = [feature_maps]
        self.feature_maps = feature_maps
        self.with_extra_blocks = with_extra_blocks
        self.extra_block_filters = extra_block_filters

        self._out_channels = []

        self.conv1 = ConvBNLayer(
            in_channels=1,
            out_channels=int(32*prune_ratios[0] * scale),
            kernel_size=3,
            stride=2,
            padding=1,
            conv_lr=conv_learning_rate,
            conv_decay=conv_decay,
            norm_decay=norm_decay,
            norm_type=norm_type,
            name="conv1")

        self.dwsl = []
        dws21 = self.add_sublayer(
            "conv2_1",
            sublayer=DepthwiseSeparable(
                in_channels=int(32*prune_ratios[0] * scale),
                out_channels1=32*prune_ratios[0],
                out_channels2=64*prune_ratios[1],
                num_groups=32*prune_ratios[0],
                stride=1,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv2_1"))
        self.dwsl.append(dws21)
        self._update_out_channels(64*prune_ratios[1], len(self.dwsl), feature_maps)
        dws22 = self.add_sublayer(
            "conv2_2",
            sublayer=DepthwiseSeparable(
                in_channels=int(64 *prune_ratios[1]* scale),
                out_channels1=64*prune_ratios[1],
                out_channels2=128*prune_ratios[2],
                num_groups=64*prune_ratios[1],
                stride=2,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv2_2"))
        self.dwsl.append(dws22)
        self._update_out_channels(128*prune_ratios[2], len(self.dwsl), feature_maps)
        # 1/4
        dws31 = self.add_sublayer(
            "conv3_1",
            sublayer=DepthwiseSeparable(
                in_channels=int(128*prune_ratios[2] * scale),
                out_channels1=128*prune_ratios[2],
                out_channels2=128*prune_ratios[3],#128
                num_groups=128*prune_ratios[2],
                stride=1,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv3_1"))
        self.dwsl.append(dws31)
        self._update_out_channels(128*prune_ratios[3], len(self.dwsl), feature_maps)
        dws32 = self.add_sublayer(
            "conv3_2",
            sublayer=DepthwiseSeparable(
                in_channels=int(128 *prune_ratios[3]* scale),
                out_channels1=128*prune_ratios[3],
                out_channels2=256*prune_ratios[4],
                num_groups=128*prune_ratios[3],
                stride=2,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv3_2"))
        self.dwsl.append(dws32)
        self._update_out_channels(256*prune_ratios[4], len(self.dwsl), feature_maps)
        # 1/8
        dws41 = self.add_sublayer(
            "conv4_1",
            sublayer=DepthwiseSeparable(
                in_channels=int(256 *prune_ratios[4]* scale),
                out_channels1=256*prune_ratios[4],
                out_channels2=256*prune_ratios[5],
                num_groups=256*prune_ratios[4],#256
                stride=1,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv4_1"))
        self.dwsl.append(dws41)
        self._update_out_channels(256*prune_ratios[5], len(self.dwsl), feature_maps)
        dws42 = self.add_sublayer(
            "conv4_2",
            sublayer=DepthwiseSeparable(
                in_channels=int(256*prune_ratios[5] * scale),
                out_channels1=256*prune_ratios[5],
                out_channels2=512*prune_ratios[6],
                num_groups=256*prune_ratios[5],
                stride=2,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv4_2"))
        self.dwsl.append(dws42)
        self._update_out_channels(512*prune_ratios[6], len(self.dwsl), feature_maps)
        1/16
        for i in range(5):
                if (i<3):
                    tmp = self.add_sublayer(
                    "conv5_" + str(i + 1),
                        sublayer=DepthwiseSeparable(
                            in_channels=int(512*prune_ratios[6+i]),#512
                            out_channels1=int(512*prune_ratios[6+i]),
                            out_channels2=int(512*prune_ratios[7+i]),
                            num_groups=int(512*prune_ratios[6+i]),
                            stride=1,
                            scale=scale,
                            conv_lr=conv_learning_rate,
                            conv_decay=conv_decay,
                            norm_decay=norm_decay,
                            norm_type=norm_type,
                            name="conv5_" + str(i + 1)))
                    self.dwsl.append(tmp)
                    self._update_out_channels(int(512*prune_ratios[7+i]), len(self.dwsl), feature_maps)
                elif(i==3):
                    tmp = self.add_sublayer(
                    "conv5_" + str(i + 1),
                        sublayer=DepthwiseSeparable(
                            in_channels=int(512*prune_ratios[6+i]),
                            out_channels1=int(512*prune_ratios[6+i]),
                            out_channels2=int(512*prune_ratios[7+i]),
                            num_groups=int(512*prune_ratios[6+i]),
                            stride=1,
                            scale=scale,
                            conv_lr=conv_learning_rate,
                            conv_decay=conv_decay,
                            norm_decay=norm_decay,
                            norm_type=norm_type,
                            name="conv5_" + str(i + 1)))
                    self.dwsl.append(tmp)
                    self._update_out_channels(int(512*prune_ratios[7+i]), len(self.dwsl), feature_maps)
                elif(i==4):
                    tmp = self.add_sublayer(
                    "conv5_" + str(i + 1),
                        sublayer=DepthwiseSeparable(
                            in_channels=int(512*prune_ratios[10]),#128
                            # in_channels=128,#128
                            out_channels1=int(512*prune_ratios[10]),
                            out_channels2=int(512*output_prune_ratios[0]),###############################
                            num_groups=int(512*prune_ratios[10]),
                            stride=1,
                            scale=scale,
                            conv_lr=conv_learning_rate,
                            conv_decay=conv_decay,
                            norm_decay=norm_decay,
                            norm_type=norm_type,
                            name="conv5_" + str(i + 1)))
                    self.dwsl.append(tmp)
                    self._update_out_channels(int(512*output_prune_ratios[0]), len(self.dwsl), feature_maps)
        dws56 = self.add_sublayer(
            "conv5_6",
            sublayer=DepthwiseSeparable(
                in_channels=int(512* output_prune_ratios[0]* scale),
                out_channels1=int(512*output_prune_ratios[0]),
                out_channels2=1024*prune_ratios[11],
                num_groups=int(512*output_prune_ratios[0]),
                stride=2,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv5_6"))
        self.dwsl.append(dws56)
        self._update_out_channels(1024*prune_ratios[11], len(self.dwsl), feature_maps)
        # 1/32
        dws6 = self.add_sublayer(
            "conv6",
            sublayer=DepthwiseSeparable(
                in_channels=int(1024*prune_ratios[11] * scale),
                out_channels1=int(1024*prune_ratios[11]),
                out_channels2=int(1024*output_prune_ratios[1]),###############################
                num_groups=int(1024*prune_ratios[11]),
                stride=1,
                scale=scale,
                conv_lr=conv_learning_rate,
                conv_decay=conv_decay,
                norm_decay=norm_decay,
                norm_type=norm_type,
                name="conv6"))
        self.dwsl.append(dws6)
        self._update_out_channels(int(1024*output_prune_ratios[1]), len(self.dwsl), feature_maps)

        if self.with_extra_blocks:
            self.extra_blocks = []
            for i, block_filter in enumerate(self.extra_block_filters):
                in_c = int(1024*output_prune_ratios[1]) if i == 0 else self.extra_block_filters[i - 1][1]
                block_filter[1]=int(output_prune_ratios[2+i]*block_filter[1])
                conv_extra = self.add_sublayer(
                    "conv7_" + str(i + 1),
                    sublayer=ExtraBlock(
                        in_c,
                        int(block_filter[0]*prune_ratios[12+i]),
                        block_filter[1],
                        conv_lr=conv_learning_rate,
                        conv_decay=conv_decay,
                        norm_decay=norm_decay,
                        norm_type=norm_type,
                        name="conv7_" + str(i + 1)))
                self.extra_blocks.append(conv_extra)
                self._update_out_channels(
                    block_filter[1],
                    len(self.dwsl) + len(self.extra_blocks), feature_maps)

    def _update_out_channels(self, channel, feature_idx, feature_maps):
        if feature_idx in feature_maps:
            self._out_channels.append(channel)

    def forward(self, inputs):
        outs = []
        y = self.conv1(inputs['image'])
        for i, block in enumerate(self.dwsl):
            y = block(y)
            if i + 1 in self.feature_maps:
                outs.append(y)

        if not self.with_extra_blocks:
            return outs

        y = outs[-1]
        for i, block in enumerate(self.extra_blocks):
            idx = i + len(self.dwsl)
            y = block(y)
            if idx + 1 in self.feature_maps:
                outs.append(y)
        return outs

    @property
    def out_shape(self):
        return [ShapeSpec(channels=c) for c in self._out_channels]
