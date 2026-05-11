#include <iostream>
#include <cuda_runtime.h>
#include <cudnn.h>

int main() {
    cudnnHandle_t handle;

    cudnnStatus_t status = cudnnCreate(&handle);

    if (status != CUDNN_STATUS_SUCCESS) {
        std::cerr << "cuDNN init FAILED: "
                  << cudnnGetErrorString(status) << std::endl;
        return 1;
    }

    std::cout << "cuDNN initialized successfully!" << std::endl;

    std::cout << "cuDNN version: "
              << cudnnGetVersion() << std::endl;

    cudnnDestroy(handle);

    return 0;
}