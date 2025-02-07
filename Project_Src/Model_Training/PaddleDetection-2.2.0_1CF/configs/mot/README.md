English | [简体中文](README_cn.md)

# MOT (Multi-Object Tracking)

## Table of Contents
- [Introduction](#Introduction)
- [Installation](#Installation)
- [Model Zoo](#Model_Zoo)
- [Feature Tracking Model](#Feature_Tracking_Model)
- [Dataset Preparation](#Dataset_Preparation)
- [Getting Start](#Getting_Start)
- [Citations](#Citations)

## Introduction
The current mainstream multi-objective tracking (MOT) algorithm is mainly composed of two parts: detection and embedding. Detection aims to detect the potential targets in each frame of the video. Embedding assigns and updates the detected target to the corresponding track (named ReID task). According to the different implementation of these two parts, it can be divided into **SDE** series and **JDE** series algorithm.

- **SDE** (Separate Detection and Embedding) is a kind of algorithm which completely separates Detection and Embedding. The most representative is **DeepSORT** algorithm. This design can make the system fit any kind of detectors without difference, and can be improved for each part separately. However, due to the series process, the speed is slow. Time-consuming is a great challenge in the construction of real-time MOT system.

- **JDE** (Joint Detection and Embedding) is to learn detection and embedding simultaneously in a shared neural network, and set the loss function with a multi task learning approach. The representative algorithms are **JDE** and **FairMOT**. This design can achieve high-precision real-time MOT performance.

Paddledetection implements three MOT algorithms of these two series.

- [DeepSORT](https://arxiv.org/abs/1812.00442) (Deep Cosine Metric Learning SORT) extends the original [SORT](https://arxiv.org/abs/1703.07402) (Simple Online and Realtime Tracking) algorithm, it adds a CNN model to extract features in image of human part bounded by a detector. It integrates appearance information based on a deep appearance descriptor, and assigns and updates the detected targets to the existing corresponding trajectories like ReID task. The detection bboxes result required by DeepSORT can be generated by any detection model, and then the saved detection result file can be loaded for tracking. Here we select the `PCB + Pyramid ResNet101` model provided by [PaddleClas](https://github.com/PaddlePaddle/PaddleClas) as the ReID model.

- [JDE](https://arxiv.org/abs/1909.12605) (Joint Detection and Embedding) learns the object detection task and appearance embedding task simutaneously in a shared neural network. And the detection results and the corresponding embeddings are also outputed at the same time. JDE original paper is based on an Anchor Base detector YOLOv3 , adding a new ReID branch to learn embeddings. The training process is constructed as a multi-task learning problem, taking into account both accuracy and speed.

- [FairMOT](https://arxiv.org/abs/2004.01888) is based on an Anchor Free detector Centernet, which overcomes the problem of anchor and feature misalignment in anchor based detection framework. The fusion of deep and shallow features enables the detection and ReID tasks to obtain the required features respectively. It also uses low dimensional ReID features. FairMOT is a simple baseline composed of two homogeneous branches propose to predict the pixel level target score and ReID features. It achieves the fairness between the two tasks and  obtains a higher level of real-time MOT performance.

<div align="center">
  <img src="../../docs/images/mot16_jde.gif" width=500 />
</div>


## Installation

Install all the related dependencies for MOT:
```
pip install lap sklearn motmetrics openpyxl cython_bbox
or
pip install -r requirements.txt
```
**Notes:**
- Install `cython_bbox` for Windows: `pip install -e git+https://github.com/samson-wang/cython_bbox.git#egg=cython-bbox`. You can refer to this [tutorial](https://stackoverflow.com/questions/60349980/is-there-a-way-to-install-cython-bbox-for-windows).
- Evaluation on Windows CUDA 11 environment may not be normally. It will be repaired as soon as possible. You can change to CUDA 10.2 or CUDA 10.1 environment for normal evaluation.


## Model Zoo

### DeepSORT Results on MOT-16 Training Set

| backbone  | input shape | MOTA | IDF1 |  IDS  |   FP  |   FN  |   FPS  | det result/model |ReID model| config |
| :---------| :------- | :----: | :----: | :--: | :----: | :---: | :---: | :---: | :---: | :---: |
| ResNet-101 | 1088x608 |  72.2  |  60.5  | 998  |  8054  | 21644 |  - | [det result](https://dataset.bj.bcebos.com/mot/det_results_dir.zip) |[ReID model](https://paddledet.bj.bcebos.com/models/mot/deepsort_pcb_pyramid_r101.pdparams)|[config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/deepsort/deepsort_pcb_pyramid_r101.yml) |
| ResNet-101 | 1088x608 |  68.3  |  56.5  | 1722 |  17337 | 15890 |  - | [det model](https://paddledet.bj.bcebos.com/models/mot/jde_yolov3_darknet53_30e_1088x608.pdparams) |[ReID model](https://paddledet.bj.bcebos.com/models/mot/deepsort_pcb_pyramid_r101.pdparams)|[config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/deepsort/deepsort_pcb_pyramid_r101.yml) |

### DeepSORT Results on MOT-16 Test Set

| backbone  | input shape | MOTA | IDF1 |  IDS  |   FP  |   FN  |   FPS  | det result/model |ReID model| config |
| :---------| :------- | :----: | :----: | :--: | :----: | :---: | :---: | :---: | :---: | :---: |
| ResNet-101 | 1088x608 |  64.1  |  53.0  | 1024  |  12457  | 51919 |  - |[det result](https://dataset.bj.bcebos.com/mot/det_results_dir.zip) |[ReID model](https://paddledet.bj.bcebos.com/models/mot/deepsort_pcb_pyramid_r101.pdparams)|[config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/deepsort/deepsort_pcb_pyramid_r101.yml) |
| ResNet-101 | 1088x608 |  61.2  |  48.5  | 1799  |  25796  | 43232 |  - | [det model](https://paddledet.bj.bcebos.com/models/mot/jde_yolov3_darknet53_30e_1088x608.pdparams)  |[ReID model](https://paddledet.bj.bcebos.com/models/mot/deepsort_pcb_pyramid_r101.pdparams)|[config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/deepsort/deepsort_pcb_pyramid_r101.yml) |

**Notes:**
DeepSORT does not need to train on MOT dataset, only used for evaluation. Now it supports two evaluation methods.

- 1.Load the result file and the ReID model. Before DeepSORT evaluation, you should get detection results by a detection model first, and then prepare them like this:
```
det_results_dir
   |——————MOT16-02.txt
   |——————MOT16-04.txt
   |——————MOT16-05.txt
   |——————MOT16-09.txt
   |——————MOT16-10.txt
   |——————MOT16-11.txt
   |——————MOT16-13.txt
```
For MOT16 dataset, you can download a detection result after matching called det_results_dir.zip provided by PaddleDetection：
```
wget https://dataset.bj.bcebos.com/mot/det_results_dir.zip
```
If you use a stronger detection model, you can get better results. Each txt is the detection result of all the pictures extracted from each video, and each line describes a bounding box with the following format:
```
[frame_id],[bb_left],[bb_top],[width],[height],[conf]
```
- `frame_id` is the frame number of the image
- `bb_left` is the X coordinate of the left bound of the object box
- `bb_top` is the Y coordinate of the upper bound of the object box
- `width,height` is the pixel width and height
- `conf` is the object score with default value `1` (the results had been filtered out according to the detection score threshold)

- 2.Load the detection model and the ReID model at the same time. Here, the JDE version of YOLOv3 is selected. For more detail of configuration, see `configs/mot/deepsort/_base_/deepsort_yolov3_darknet53_pcb_pyramid_r101.yml`.


### JDE Results on MOT-16 Training Set

| backbone           | input shape | MOTA | IDF1  |  IDS  |   FP  |  FN  |  FPS  | download | config |
| :----------------- | :------- | :----: | :----: | :---: | :----: | :---: | :---: | :---: | :---: |
| DarkNet53          | 1088x608 |  72.0  |  66.9  | 1397  |  7274  | 22209 |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_1088x608.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_1088x608.yml) |
| DarkNet53          | 864x480 |  69.1  |  64.7  | 1539  |  7544  | 25046 |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_864x480.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_864x480.yml) |
| DarkNet53          | 576x320 |  63.7  |  64.4  | 1310  |  6782  | 31964 |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_576x320.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_576x320.yml) |

### JDE Results on MOT-16 Test Set

| backbone           | input shape | MOTA | IDF1  |  IDS  |   FP  |  FN  |  FPS  | download | config |
| :----------------- | :------- | :----: | :----: | :---: | :----: | :---: | :---: | :---: | :---: |
| DarkNet53(paper)   | 1088x608 |  64.4  |  55.8  | 1544  |    -    |   -   |   -   |   -  |   -   |
| DarkNet53          | 1088x608 |  64.6  |  58.5  | 1864  |  10550 | 52088 |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_1088x608.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_1088x608.yml) |
| DarkNet53(paper)   | 864x480 |   62.1  |  56.9  | 1608  |    -    |   -   |   -   |   -  |   -   |
| DarkNet53          | 864x480 |   63.2  |  57.7  | 1966  |  10070  | 55081 |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_864x480.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_864x480.yml) |
| DarkNet53          | 576x320 |   59.1  |  56.4  | 1911  |  10923  | 61789  |   -   |[model](https://paddledet.bj.bcebos.com/models/mot/jde_darknet53_30e_576x320.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/jde/jde_darknet53_30e_576x320.yml) |

**Notes:**
 JDE used 8 GPUs for training and mini-batch size as 4 on each GPU, and trained for 30 epoches.


### FairMOT Results on MOT-16 Training Set

| backbone       | input shape | MOTA | IDF1 |  IDS  |    FP   |   FN   |    FPS    | download | config |
| :--------------| :------- | :----: | :----: | :----: | :----: | :----: | :------: | :----: |:-----: |
| DLA-34(paper)  | 1088x608 |  83.3  |  81.9  |   544  |  3822  |  14095  |     -   |    -   |   -    |
| DLA-34         | 1088x608 |  83.7  |  83.3  |   435  |  3829  |  13764  |     -   | [model](https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml) |


### FairMOT Results on MOT-16 Test Set

| backbone       | input shape | MOTA | IDF1 |  IDS  |    FP   |   FN   |    FPS    | download | config |
| :--------------| :------- | :----: | :----: | :----: | :----: | :----: | :------: | :----: |:-----: |
| DLA-34(paper)  | 1088x608 |  74.9  |  72.8  |  1074  |    -   |    -   |   25.9   |    -   |   -    |
| DLA-34         | 1088x608 |  74.8  |  74.4  |  930   |  7038  |  37994 |    -     | [model](https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml) |

**Notes:**
 FairMOT used 8 GPUs for training and mini-batch size as 6 on each GPU, and trained for 30 epoches.


## Feature Tracking Model

### 【Head Tracking](./headtracking21/README.md)

### FairMOT Results on HT-21 Training Set
|    backbone      |  input shape |  MOTA  |  IDF1  |  IDS  |   FP  |   FN   |   FPS   |  download | config |
| :--------------| :------- | :----: | :----: | :---: | :----: | :---: | :------: | :----: |:----: |
| DLA-34         | 1088x608 |  67.2 |  70.4  |   9403  |  124840  |  255007  |     -   | [model](https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608_headtracking21.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/headtracking21/fairmot_dla34_30e_1088x608_headtracking21.yml) |

### FairMOT Results on HT-21 Test Set
|    backbone      |  input shape |  MOTA  |  IDF1  |  IDS  |   FP  |   FN   |   FPS   |  download | config |
| :--------------| :------- | :----: | :----: | :----: | :----: | :----: |:-------: | :----: | :----: |
| DLA-34         | 1088x608 |  58.2  |  61.3  |  13166   |  141872  |  197074 |    -     | [model](https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608_headtracking21.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/headtracking21/fairmot_dla34_30e_1088x608_headtracking21.yml) |

### [Vehicle Tracking](./kitticars/README.md)
### FairMOT Results on KITTI tracking (2D bounding-boxes) Training Set (Car)

|    backbone    | input shape |  MOTA   |   FPS   |  download | config |
| :--------------| :------- | :-----: | :-----: | :------: | :----: |
| DLA-34         | 1088x608 |   67.9  |    -    |[model](https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608_kitticars.pdparams) | [config](https://github.com/PaddlePaddle/PaddleDetection/tree/release/2.2/configs/mot/kitticars/fairmot_dla34_30e_1088x608_kitticars.yml) |


## Dataset Preparation

### MOT Dataset
PaddleDetection use the same training data as [JDE](https://github.com/Zhongdao/Towards-Realtime-MOT) and [FairMOT](https://github.com/ifzhang/FairMOT). Please refer to [PrepareMOTDataSet](../../docs/tutorials/PrepareMOTDataSet.md) to download and prepare all the training data including **Caltech Pedestrian, CityPersons, CUHK-SYSU, PRW, ETHZ, MOT17 and MOT16**. The former six are used as the mixed dataset for training, and MOT16 are used as the evaluation dataset. In addition, you can use **MOT15 and MOT20** for finetune. All pedestrians in these datasets have detection bbox labels and some have ID labels. If you want to use these datasets, please **follow their licenses**.

### Data Format
These several relevant datasets have the following structure:
```
Caltech
   |——————images
   |        └——————00001.jpg
   |        |—————— ...
   |        └——————0000N.jpg
   └——————labels_with_ids
            └——————00001.txt
            |—————— ...
            └——————0000N.txt
MOT17
   |——————images
   |        └——————train
   |        └——————test
   └——————labels_with_ids
            └——————train
```
Annotations of these datasets are provided in a unified format. Every image has a corresponding annotation text. Given an image path, the annotation text path can be generated by replacing the string `images` with `labels_with_ids` and replacing `.jpg` with `.txt`.

In the annotation text, each line is describing a bounding box and has the following format:
```
[class] [identity] [x_center] [y_center] [width] [height]
```
**Notes:**
- `class` should be `0`. Only single-class multi-object tracking is supported now.
- `identity` is an integer from `1` to `num_identities`(`num_identities` is the total number of instances of objects in the dataset), or `-1` if this box has no identity annotation.
- `[x_center] [y_center] [width] [height]` are the center coordinates, width and height, note that they are normalized by the width/height of the image, so they are floating point numbers ranging from 0 to 1.

### Dataset Directory

First, follow the command below to download the `image_list.zip` and unzip it in the `dataset/mot` directory:
```
wget https://dataset.bj.bcebos.com/mot/image_lists.zip
```
Then download and unzip each dataset, and the final directory is as follows:
```
dataset/mot
  |——————image_lists
            |——————caltech.10k.val  
            |——————caltech.all  
            |——————caltech.train  
            |——————caltech.val  
            |——————citypersons.train  
            |——————citypersons.val  
            |——————cuhksysu.train  
            |——————cuhksysu.val  
            |——————eth.train  
            |——————mot15.train  
            |——————mot16.train  
            |——————mot17.train  
            |——————mot20.train  
            |——————prw.train  
            |——————prw.val
  |——————Caltech
  |——————Cityscapes
  |——————CUHKSYSU
  |——————ETHZ
  |——————MOT15
  |——————MOT16
  |——————MOT17
  |——————MOT20
  |——————PRW
```

## Getting Start

### 1. Training

Training FairMOT on 8 GPUs with following command

```bash
python -m paddle.distributed.launch --log_dir=./fairmot_dla34_30e_1088x608/ --gpus 0,1,2,3,4,5,6,7 tools/train.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml
```

### 2. Evaluation

Evaluating the track performance of FairMOT on val dataset in single GPU with following commands:

```bash
# use weights released in PaddleDetection model zoo
CUDA_VISIBLE_DEVICES=0 python tools/eval_mot.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml -o weights=https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams

# use saved checkpoint in training
CUDA_VISIBLE_DEVICES=0 python tools/eval_mot.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml -o weights=output/fairmot_dla34_30e_1088x608/model_final.pdparams
```
**Notes:**
 The default evaluation dataset is MOT-16 Train Set. If you want to change the evaluation dataset, please refer to the following code and modify `configs/datasets/mot.yml`, modify `data_root`：
```
EvalMOTDataset:
  !MOTImageFolder
    dataset_dir: dataset/mot
    data_root: MOT17/images/train
    keep_ori_im: False # set True if save visualization images or video
```

### 3. Inference

Inference a vidoe on single GPU with following command:

```bash
# inference on video and save a video
CUDA_VISIBLE_DEVICES=0 python tools/infer_mot.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml -o weights=https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams --video_file={your video name}.mp4 --frame_rate=20 --save_videos
```

Inference a image folder on single GPU with following command:

```bash
# inference image folder and save a video
CUDA_VISIBLE_DEVICES=0 python tools/infer_mot.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml -o weights=https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams --image_dir={your infer images folder} --save_videos
```

**Notes:**
 Please make sure that [ffmpeg](https://ffmpeg.org/ffmpeg.html) is installed first, on Linux(Ubuntu) platform you can directly install it by the following command:`apt-get update && apt-get install -y ffmpeg`. `--frame_rate` means the frame rate of the video and the frames extracted per second. It can be set by yourself, default value is -1 indicating the video frame rate read by OpenCV.


### 4. Export model

```bash
CUDA_VISIBLE_DEVICES=0 python tools/export_model.py -c configs/mot/fairmot/fairmot_dla34_30e_1088x608.yml -o weights=https://paddledet.bj.bcebos.com/models/mot/fairmot_dla34_30e_1088x608.pdparams
```

### 5. Using exported model for python inference

```bash
python deploy/python/mot_jde_infer.py --model_dir=output_inference/fairmot_dla34_30e_1088x608 --video_file={your video name}.mp4 --device=GPU --save_mot_txts
```
**Notes:**
The tracking model is used to predict the video, and does not support the prediction of a single image. The visualization video of the tracking results is saved by default. You can add `--save_mot_txts` to save the txt result file, or `--save_images` to save the visualization images.

### 6. Using exported MOT and keypoint model for unite python inference

```bash
python deploy/python/mot_keypoint_unite_infer.py --mot_model_dir=output_inference/fairmot_dla34_30e_1088x608/ --keypoint_model_dir=output_inference/higherhrnet_hrnet_w32_512/ --video_file={your video name}.mp4 --device=GPU
```
**Notes:**
 Keypoint model export tutorial: `configs/keypoint/README.md`.

## Citations
```
@inproceedings{Wojke2017simple,
  title={Simple Online and Realtime Tracking with a Deep Association Metric},
  author={Wojke, Nicolai and Bewley, Alex and Paulus, Dietrich},
  booktitle={2017 IEEE International Conference on Image Processing (ICIP)},
  year={2017},
  pages={3645--3649},
  organization={IEEE},
  doi={10.1109/ICIP.2017.8296962}
}

@inproceedings{Wojke2018deep,
  title={Deep Cosine Metric Learning for Person Re-identification},
  author={Wojke, Nicolai and Bewley, Alex},
  booktitle={2018 IEEE Winter Conference on Applications of Computer Vision (WACV)},
  year={2018},
  pages={748--756},
  organization={IEEE},
  doi={10.1109/WACV.2018.00087}
}

@article{wang2019towards,
  title={Towards Real-Time Multi-Object Tracking},
  author={Wang, Zhongdao and Zheng, Liang and Liu, Yixuan and Wang, Shengjin},
  journal={arXiv preprint arXiv:1909.12605},
  year={2019}
}

@article{zhang2020fair,
  title={FairMOT: On the Fairness of Detection and Re-Identification in Multiple Object Tracking},
  author={Zhang, Yifu and Wang, Chunyu and Wang, Xinggang and Zeng, Wenjun and Liu, Wenyu},
  journal={arXiv preprint arXiv:2004.01888},
  year={2020}
}
```
