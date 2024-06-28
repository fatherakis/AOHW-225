# AOHW-225
Adversarial Robustness Strategies for Neural Networks in Versal platforms Project for AMD Open Hardware 2024 design contest.

All generated model files and datasets:
https://drive.google.com/drive/folders/1Xzx2EW_L9vyqk_OIrdAezwPlTJUg2nLw?usp=sharing

This Project along with its run instructions can be split in 3 segments:

1. [Model Retraining](#model-retraining)
2. [Vitis AI Conversion](#vitis-ai-30)
3. [Versal Execution](#versal)

> [!Note]
> We use MobileNetV2 for the intentions of this project.

## Model Retraining

In this segment we first generate adversarial examples using HopSkipJumpAttack algorithm which are then used to train the model on. Due to the nature of this project, the resources and data it requires, we provide all intermediate trained steps in the Google Drive above.

As such this segment is purely for demonstration purposes. (Fully functional but not advised to execute.)

Step 1: Install all python dependencies.\
``./dependencies.sh`` 
> [!Important]
> If you use pip instead of pip3 for python3  you need to update the script accordingly.

Step 2: Generate Adversarial Examples for each adversarial iteration.

Run the [MobileNet_Adversarial_Example_Gen](resources/Model_Resources/MobileNet_Adversarial_Example_Gen.ipynb) jupyter notebook.

This notebook generates examples for all training iterations and as such it requires the corresponding trained versions (eg. generation of 2nd set of examples requires the model trained on the 1st set). All model sub-versions are loaded from our drive by default.

Step 3: Re-train MobileNetV2 on generated examples

Steps 2 and 3 should run in conjunction with each other: generate examples -> retrain model.\
For this reason, [Ader_Train_separate](resources/Model_Resources/Adver_Train_separate/) folder, contains a retrain notebook for each Adversarial Training iteration. Otherwise, [MobileNet_Adversrial_Training](resources/Model_Resources/MobileNet_Adversarial_Training.ipynb) notebook provides the same functionality with all training iterations combined.

Step 4: Quantization

Simply run [MobileNet_Adversrial_PTSQ](resources/Model_Resources/MobileNet_Adversarial_PTSQ.ipynb) notebook through jupyter in order to Quantize and export the model in each training iteration (1, 2, 3)

Step 5: Metrics Generation

Run [Mobilenet_Adversarial_Metrics_Gen](resources/Model_Resources/MobileNet_Adversarial_Metrics_Gen.ipynb) notebook to generate adversarial examples on the test set for each model version (8  versions: 4 floating point & 4 int8 quantized).\
A PSNR difference calculation for each model version is also included.


## Vitis-AI 3.0

Finishing with our adversarial retraining procedure, lets quantize and convert our finalized model using VAI 3.0.
> [!CAUTION]
> Our board Versal AI Core Series VCK190 requires use of VitisAI 3.0
### Setup 
Step 1: Install [Docker](https://www.docker.com/).

Step 2: Clone [Vitis-AI 3.0]() repository.\
``git clone --branch 3.0 https://github.com/Xilinx/Vitis-AI.git``\

Step 3: Pull VitisAI Docker Container.\
``docker pull xilinx/vitis-ai-python-cpu:latest``

Step 4: Run Vitis Docker.\
``cd <Vitis-AI install path>/Vitis-AI``\
``./docker_run.sh xilinx/vitis-ai-pytorch-cpu:latest``

### Quantization
In this part we have VitisAI 3.0 up and running and we are ready to quantize our final (fp) model in order to run on versal.

Step 5: Copy [Vitis_AI](resources/Vitis_AI/) folder in your VitisAI install path workspace.

**After copying**, in the docker container terminal:\
``cd Vitis_AI``

Step 6: Enable the python environment in container.\
``conda activate vitis-ai-pytorch``

Step 7: Make sure we have pytorch installed.\
``pip install torch torchvision``

Step 8: Extract CIFAR-10 set for calibration.\
``cd dataset``\
``tar -xf cifar.tar``

Step 8.5: Go back.\
``cd ..``

Step 9: Run quantization script for calibration.\
``python mobilenet_cifar_model.py --data_dir Vitis_AI/dataset/cifar/ --model_dir Vitis_AI/ --quant_mode calib --target DPUCVDX8G_ISA3_C32B6``

> [!IMPORTANT]
> If you get an error for a missing file "MobileNetV2.py" or parameter issue, simply re-run the command and it should be fine.

Step 10: Run test mode and deployment.

``python mobilenet_cifar_model.py --data_dir Vitis_AI/dataset/cifar/ --model_dir Vitis_AI/ --model_name --quant_mode test --batch_size 1 --target DPUCVDX8G_ISA3_C32B6 --deploy``


### Deployment

Step 11: Prepare for board requirements.

``/workspace/board_setup/vck190/host_cross_compiler_setup.sh``

After its done you also have to run\
``unset LD_LIBRARY_PATH``\
``source $install_path/environment-setup-cortexa72-cortexa53-xilinx-linux``\
Where $install_path should be provided from the terminal output as the whole command.

Step 12: Compile Quantized model for our device.

``vai_c_xir -x quantize_result/MobileNetV2_int.xmodel -a /opt/vitis_ai/compiler/arch/DPUCVDX8G/VCK190/arch.json -o ./ -n mobilenetCIFAR``


## Versal

Our model is retrained and ready. Now we can transfer our code available in [Versal_Files](resources/Versal_Files/) and deployed model to our board and run some tests.

First you have to pick the test dataset you want to test. CIFAR-10 1000 example test set is preloaded.

Here are your options:


*  Normal CIFAR-10 (1000 examples): Preloaded as test.tar

*  Adversarial Examples Train Set **after No Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1eZiyid20FNlgYf1s_UDp_WuG3ME9BWBX&export=download&confirm=t&uuid=0
*  Adversarial Examples from Train Set **after 1st Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=134gt5C14vi-12J3YI-BjOVqJrOP__0sJ&export=download&confirm=t&uuid=0
*  Adversarial Examples from Train Set **after 2nd Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1M3eBI153j4eIJD_ks1FoHe1C0ZWiW4EA&export=download&confirm=t&uuid=0
*  Adversarial Examples from Train Set **after Final Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1mzXj3HGzGLoyvEfs0h6L2Qbmnad643Mm&export=download&confirm=t&uuid=0
*  Adversarial Examples from Test Set **after No Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1j6QnvHAhAEs17AfG4iFldpLsv2bXkImi&export=download&confirm=t&uuid=0
*  Adversarial Examples from Test Set **after 1st Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1YlfBQQh5vb_QB3jW2NxvFDwMSVsYF6TL&export=download&confirm=t&uuid=0
*  Adversarial Examples from Test Set **after 2nd Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1V1ye7Fjh6vLkDxLnO6tfe-our-yD-cKK&export=download&confirm=t&uuid=0
*  Adversarial Examples from Test Set **after Final Retraining** (400 examples):\
https://drive.usercontent.google.com/download?id=1fDmjWv_jAE6xQb6aGHJ98fTFPWf0Q5QB&export=download&confirm=t&uuid=0

> [!Note]
> If you pick a different set other than the default test.tar don't forget to rename it to "test.tar"

Step 1 (Optional): Move desired set in Versal_Files folder.

Step 2: Compress archive for easier transfer.\
`` tar -cf versal.tar Versal_Files/``

Step 3: Transfer to Versal via usb/microSD or remotely.\
For remote transfer: ``scp versal.tar <user>@<versal_ip>:~/``

Step 4: **On versal**, extract the archive.\
``tar -xf versal.tar``
``cd Versal_Files``

Step 5: Run the model.\
``./run_src.sh <#examples>``

Where <#examples> should be the number of examples in the dataset (1000 for default, 400 for our generated ones).

Step 6: Retrieve all results from rpt folder.\
``mv model_src/rpt ~/``
``cd ..``

Step 7: Compress results to further examine on your own device.\
``tar -cf results.tar rpt/``

Step 8: Retrieve the archive via usb/microSD or remotely.\
For remote acquisition: ``scp <user>@<versal_ip>:~/results.tar ~/Downloads/``