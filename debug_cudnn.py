import torch
import torch.nn.functional as F

print("Torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
print("CUDA version:", torch.version.cuda)
print("cuDNN available:", torch.backends.cudnn.is_available())
print("cuDNN version:", torch.backends.cudnn.version())

# Device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Using device:", device)

# Simple 2D convolution test
x = torch.randn(1, 1, 8, 8, device=device)      # NCHW
w = torch.randn(1, 1, 3, 3, device=device)      # out_ch, in_ch, kH, kW

y = F.conv2d(x, w, padding=1)

print("Conv2D output shape:", y.shape)
print("Conv2D output sum:", y.sum().item())
