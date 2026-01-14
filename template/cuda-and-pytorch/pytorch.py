import torch
import sys

print("--- Environment Check ---")
print(f"Python: {sys.version.split()[0]}")
print(f"PyTorch: {torch.__version__}")
print(f"CUDA (PyTorch): {torch.version.cuda}")
print(f"cuDNN: {torch.backends.cudnn.version()}")

if torch.cuda.is_available():
    print("\n--- GPU Details ---")
    device_id = 0
    props = torch.cuda.get_device_properties(device_id)
    print(f"Device Name: {props.name}")
    print(f"Compute Capability: {props.major}.{props.minor}")
    print(f"Total Memory: {props.total_memory / 1024**3:.2f} GB")
    
    print("\n--- Performance Test (Matrix Mul) ---")
    try:
        size = 8192
        print(f"Initializing {size}x{size} tensors (float16)...")
        x = torch.randn(size, size, device='cuda', dtype=torch.float16)
        y = torch.randn(size, size, device='cuda', dtype=torch.float16)
        
        torch.matmul(x, y)
        
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        
        start.record()
        z = torch.matmul(x, y)
        end.record()
        
        torch.cuda.synchronize()
        print(f"Success! Execution time: {start.elapsed_time(end):.2f} ms")
        print(f"Result shape: {z.shape}")
    except Exception as e:
        print(f"Calculation Failed: {e}")
else:
    print("Error: CUDA is not available. Please check the host driver.")