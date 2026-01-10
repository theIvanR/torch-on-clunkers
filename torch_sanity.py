import torch

print("\n===== PyTorch Sanity Check =====\n")

# Version info
print("Torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

# List devices
if torch.cuda.is_available():
    print("\nDetected CUDA devices:")
    for i in range(torch.cuda.device_count()):
        name = torch.cuda.get_device_name(i)
        cap  = torch.cuda.get_device_capability(i)
        print(f"  [{i}] {name}  |  Capability: {cap}")
else:
    print("\nNo CUDA devices detected.")

# Simple computation test
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("\nUsing device:", device)

a = torch.randn(1024, 1024, device=device)
b = torch.randn(1024, 1024, device=device)

c = a @ b   # matrix multiply

print("\nComputation successful.")
print("Result mean:", c.mean().item())

print("\n===== Done =====\n")
