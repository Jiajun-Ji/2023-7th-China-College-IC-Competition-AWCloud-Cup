# Copyright (c) 2020 PaddlePaddle Authors. All Rights Reserved. 
#   
# Licensed under the Apache License, Version 2.0 (the "License");   
# you may not use this file except in compliance with the License.  
# You may obtain a copy of the License at   
#   
#     http://www.apache.org/licenses/LICENSE-2.0    
#   
# Unless required by applicable law or agreed to in writing, software   
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
# See the License for the specific language governing permissions and   
# limitations under the License.

import paddle
import paddle.nn as nn
import paddle.nn.functional as F
from ppdet.core.workspace import register
from paddle.regularizer import L2Decay
from paddle import ParamAttr
from paddle.fluid.contrib.slim.quantization.imperative import quant_nn
from ..layers import AnchorGeneratorSSD


class NormConvLayer(nn.Layer):
    def __init__(self,
                 in_channels,
                 out_channels,
                 kernel_size=3,
                 padding=1):
        super(NormConvLayer, self).__init__()
        self.conv = nn.Conv2D(
            in_channels=in_channels,
            out_channels=out_channels,
            kernel_size=kernel_size,
            padding=padding)

    def forward(self, x):
        x = self.conv(x)
        return x


class SepConvLayer(nn.Layer):
    def __init__(self,
                 in_channels,
                 out_channels,
                 kernel_size=3,
                 padding=1,
                 conv_decay=0):
        super(SepConvLayer, self).__init__()
        self.dw_conv = nn.Conv2D(
            in_channels=in_channels,
            out_channels=in_channels,
            kernel_size=kernel_size,
            stride=1,
            padding=padding,
            groups=in_channels,
            weight_attr=ParamAttr(regularizer=L2Decay(conv_decay)),
            bias_attr=False)

        self.bn = nn.BatchNorm2D(
            in_channels,
            weight_attr=ParamAttr(regularizer=L2Decay(0.)),
            bias_attr=ParamAttr(regularizer=L2Decay(0.)))

        self.pw_conv = nn.Conv2D(
            in_channels=in_channels,
            out_channels=out_channels,
            kernel_size=1,
            stride=1,
            padding=0,
            weight_attr=ParamAttr(regularizer=L2Decay(conv_decay)),
            bias_attr=False)

    def forward(self, x):
        x = self.dw_conv(x)
        x = F.relu6(self.bn(x))
        x = self.pw_conv(x)
        return x

@register
class SSDHead(nn.Layer):
    """
    SSDHead

    Args:
        num_classes (int): Number of classes
        in_channels (list): Number of channels per input feature
        anchor_generator (dict): Configuration of 'AnchorGeneratorSSD' instance
        kernel_size (int): Conv kernel size
        padding (int): Conv padding
        use_sepconv (bool): Use SepConvLayer if true
        conv_decay (float): Conv regularization coeff
        loss (object): 'SSDLoss' instance
    """

    __shared__ = ['num_classes']
    __inject__ = ['anchor_generator', 'loss']

    def __init__(self,
                 num_classes=80,
                 in_channels=(512, 1024, 512, 256, 256, 256),
                 anchor_generator=AnchorGeneratorSSD().__dict__,
                 kernel_size=3,
                 padding=1,
                 use_sepconv=False,
                 conv_decay=0.,
                 loss='SSDLoss'):
        super(SSDHead, self).__init__()
        # add background class
        self.num_classes = num_classes + 1
        self.in_channels = in_channels
        self.anchor_generator = anchor_generator
        self.loss = loss

        if isinstance(anchor_generator, dict):
            self.anchor_generator = AnchorGeneratorSSD(**anchor_generator)

        self.num_priors = self.anchor_generator.num_priors
        self.box_convs = []
        self.score_convs = []
        # ---------------------------------------------------------------------------------------
        # 定义了18个量化结点；前面12个是在transpose2前面插入量化结点；后面是在prior_box插入量化结点
        # 6个量化结点，插入到左边transport2前面
        self.box_quantize0 = quant_nn.FakeQuantMovingAverage(name="box_quantize0")
        self.box_quantize1 = quant_nn.FakeQuantMovingAverage(name="box_quantize1")
        self.box_quantize2 = quant_nn.FakeQuantMovingAverage(name="box_quantize2")
        self.box_quantize3 = quant_nn.FakeQuantMovingAverage(name="box_quantize3")
        self.box_quantize4 = quant_nn.FakeQuantMovingAverage(name="box_quantize4")
        self.box_quantize5 = quant_nn.FakeQuantMovingAverage(name="box_quantize5")
        # 6个量化结点，插入到右边transport2前面
        self.score_quantize0 = quant_nn.FakeQuantMovingAverage(name="score_quantize0")
        self.score_quantize1 = quant_nn.FakeQuantMovingAverage(name="score_quantize1")
        self.score_quantize2 = quant_nn.FakeQuantMovingAverage(name="score_quantize2")
        self.score_quantize3 = quant_nn.FakeQuantMovingAverage(name="score_quantize3")
        self.score_quantize4 = quant_nn.FakeQuantMovingAverage(name="score_quantize4")
        self.score_quantize5 = quant_nn.FakeQuantMovingAverage(name="score_quantize5")
        
        self.prior_quantize0 = quant_nn.FakeQuantMovingAverage(name="prior_quantize0")
        self.prior_quantize1 = quant_nn.FakeQuantMovingAverage(name="prior_quantize1")
        self.prior_quantize2 = quant_nn.FakeQuantMovingAverage(name="prior_quantize2")
        self.prior_quantize3 = quant_nn.FakeQuantMovingAverage(name="prior_quantize3")
        self.prior_quantize4 = quant_nn.FakeQuantMovingAverage(name="prior_quantize4")
        self.prior_quantize5 = quant_nn.FakeQuantMovingAverage(name="prior_quantize5")



        for i, num_prior in enumerate(self.num_priors):
            box_conv_name = "boxes{}".format(i)
            if not use_sepconv:
                box_conv = self.add_sublayer(
                    box_conv_name,
                    NormConvLayer(
                    # nn.Conv2D(
                        in_channels=in_channels[i],
                        out_channels=num_prior * 4,
                        kernel_size=kernel_size,
                        padding=padding))
            else:
                box_conv = self.add_sublayer(
                    box_conv_name,
                    SepConvLayer(
                        in_channels=in_channels[i],
                        out_channels=num_prior * 4,
                        kernel_size=kernel_size,
                        padding=padding,
                        conv_decay=conv_decay))
            self.box_convs.append(box_conv)

            score_conv_name = "scores{}".format(i)
            if not use_sepconv:
                score_conv = self.add_sublayer(
                    score_conv_name,
                    NormConvLayer(
                    # nn.Conv2D(
                        in_channels=in_channels[i],
                        out_channels=num_prior * self.num_classes,
                        kernel_size=kernel_size,
                        padding=padding))
            else:
                score_conv = self.add_sublayer(
                    score_conv_name,
                    SepConvLayer(
                        in_channels=in_channels[i],
                        out_channels=num_prior * self.num_classes,
                        kernel_size=kernel_size,
                        padding=padding,
                        conv_decay=conv_decay))
            self.score_convs.append(score_conv)

    @classmethod
    def from_config(cls, cfg, input_shape):
        return {'in_channels': [i.channels for i in input_shape], }

    def forward(self, feats, image, gt_bbox=None, gt_class=None):
        box_preds = []
        cls_scores = []
        # i==0
        box_pred = self.box_convs[0](feats[0])
        box_pred = self.box_quantize0(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[0](feats[0])
        cls_score = self.score_quantize0(cls_score) # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)
        # i==1
        box_pred = self.box_convs[1](feats[1])
        box_pred = self.box_quantize1(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[1](feats[1])
        cls_score = self.score_quantize1(cls_score)  # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)
        # i==2
        box_pred = self.box_convs[2](feats[2])
        box_pred = self.box_quantize2(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[2](feats[2])
        cls_score = self.score_quantize2(cls_score) # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)
        # i==3
        box_pred = self.box_convs[3](feats[3])
        box_pred = self.box_quantize3(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[3](feats[3])
        cls_score = self.score_quantize3(cls_score) # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)
        # i==4
        box_pred = self.box_convs[4](feats[4])
        box_pred = self.box_quantize4(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[4](feats[4])
        cls_score = self.score_quantize4(cls_score) # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)
        # i==5
        box_pred = self.box_convs[5](feats[5])
        box_pred = self.box_quantize5(box_pred) # 添加量化结点
        box_pred = paddle.transpose(box_pred, [0, 2, 3, 1])
        box_pred = paddle.reshape(box_pred, [0, -1, 4])
        box_preds.append(box_pred)

        cls_score = self.score_convs[5](feats[5])
        cls_score = self.score_quantize5(cls_score) # 添加量化结点
        cls_score = paddle.transpose(cls_score, [0, 2, 3, 1])
        cls_score = paddle.reshape(cls_score, [0, -1, self.num_classes])
        cls_scores.append(cls_score)

        prior_boxes = self.anchor_generator(feats, image, self.prior_quantize0, self.prior_quantize1,
                                            self.prior_quantize2, self.prior_quantize3,
                                            self.prior_quantize4, self.prior_quantize5)

        if self.training:
            return self.get_loss(box_preds, cls_scores, gt_bbox, gt_class,
                                 prior_boxes)
        else:
            return (box_preds, cls_scores), prior_boxes

    def get_loss(self, boxes, scores, gt_bbox, gt_class, prior_boxes):
        return self.loss(boxes, scores, gt_bbox, gt_class, prior_boxes)
