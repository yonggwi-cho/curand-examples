/*
 * This program uses the device CURAND API to calculate what 
 * proportion of pseudo-random ints have low bit set.
 * It then generates uniform results to calculate how many
 * are greater than .5.
 * It then generates  normal results to calculate how many 
 * are within one standard deviation of the mean.
 */
#include <stdio.h>
#include <stdlib.h>

#include <cuda.h>
#include <curand_kernel.h>

#define CUDA_CALL(x) do { if((x) != cudaSuccess) { \
    printf("Error at %s:%d\n",__FILE__,__LINE__); \
    return EXIT_FAILURE;}} while(0)

__global__ void setup_kernel(curandState *state)
{
    int id = threadIdx.x + blockIdx.x * 64;
    /* Each thread gets same seed, a different sequence 
       number, no offset */
    curand_init(1234, id, 0, &state[id]);
    //curand_init(id, 0, 0, &state[id]);
}

__global__ void generate_normal_kernel(curandState *state,
                                int n, 
                                float *result)
{
    int id = threadIdx.x + blockIdx.x * 64;
    float x;
    /* Copy state to local memory for efficiency */
    curandState localState = state[id];
    /* Generate pseudo-random normals */
    for(int i = 0; i < n; i++) {
        x = curand_normal(&localState);
    }
    /* Copy state back to global memory */
    state[id] = localState;
    /* Store results */
    result[id] = x;
}


int main(int argc, char *argv[])
{

    int i;
    unsigned int total;
    curandState *devStates;
    //unsigned int *devResults, *hostResults;
    float *devResults, *hostResults;
    bool useMRG = 0;
    bool usePHILOX = 0;
    int sampleCount = 10000;
    bool doubleSupported = 0;
    int device;
    struct cudaDeviceProp properties;

    /* check for double precision support */
    CUDA_CALL(cudaGetDevice(&device));
    CUDA_CALL(cudaGetDeviceProperties(&properties,device));
    if ( properties.major >= 2 || (properties.major == 1 && properties.minor >= 3) ) {
        doubleSupported = 1;
    }
    
    /* Allocate space for results on host */
    hostResults = (float *)calloc(64 * 64, sizeof(float));

    /* Allocate space for results on device */
    CUDA_CALL(cudaMalloc((void **)&devResults, 64 * 64 * 
              sizeof(float)));

    /* Set results to 0 */
    CUDA_CALL(cudaMemset(devResults, 0, 64 * 64 * 
              sizeof(float)));

    /* Allocate space for prng states on device */
    CUDA_CALL(cudaMalloc((void **)&devStates, 64 * 64 * 
                  sizeof(curandState)));
    
    /* Setup prng states */
    setup_kernel<<<64, 64>>>(devStates);
    
    /* Set results to 0 */
    CUDA_CALL(cudaMemset(devResults, 0, 64 * 64 * 
              sizeof(float)));

    /* Generate and use normal pseudo-random  */
    for(i = 0; i < 50; i++) {
      generate_normal_kernel<<<64, 64>>>(devStates, sampleCount, devResults);
    }

    /* Copy device memory to host */
    CUDA_CALL(cudaMemcpy(hostResults, devResults, 64 * 64 * 
        sizeof(float), cudaMemcpyDeviceToHost));

    /* Show result */
    total = 0;
    for(i = 0; i < 64 * 64; i++) {
      printf("%lf\n",hostResults[i]);
    }

    /* Cleanup */
    CUDA_CALL(cudaFree(devStates));
    CUDA_CALL(cudaFree(devResults));
    free(hostResults);
    return EXIT_SUCCESS;
}
