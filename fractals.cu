#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// image dimensions
#define WIDTH 1920
#define HEIGHT 1080
#define MAX_ITER 1000

// color structure
struct Color {
    unsigned char r, g, b;
};

// complex number operations
__device__ float2 complex_mul(float2 a, float2 b) {
    return make_float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

__device__ float complex_mag_squared(float2 c) {
    return c.x * c.x + c.y * c.y;
}

// smooth coloring function
__device__ Color get_color(int iter, float smooth_iter) {
    if (iter == MAX_ITER) {
        return {0, 0, 0}; // black for points in the set
    }
    
    // create rainbow gradient with smooth transitions
    float t = (iter + smooth_iter) * 0.05f;
    float r = 0.5f + 0.5f * sinf(t);
    float g = 0.5f + 0.5f * sinf(t + 2.094f); // 2π/3
    float b = 0.5f + 0.5f * sinf(t + 4.188f); // 4π/3
    
    // add some brightness variation
    float brightness = 1.0f - expf(-0.1f * iter);
    
    return {
        (unsigned char)(255 * r * brightness),
        (unsigned char)(255 * g * brightness),
        (unsigned char)(255 * b * brightness)
    };
}

// CUDA kernel for mandelbrot set computation
__global__ void mandelbrot_kernel(Color* image, int width, int height, 
                                  double center_x, double center_y, double zoom) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x >= width || y >= height) return;
    
    // map pixel coordinates to complex plane
    double scale = 4.0 / (zoom * min(width, height));
    double real = center_x + (x - width / 2.0) * scale;
    double imag = center_y + (y - height / 2.0) * scale;
    
    float2 c = make_float2(real, imag);
    float2 z = make_float2(0.0f, 0.0f);
    
    int iter = 0;
    float mag_sq = 0.0f;
    
    // mandelbrot iteration with early bailout
    while (iter < MAX_ITER && mag_sq < 16.0f) {
        z = complex_mul(z, z);
        z.x += c.x;
        z.y += c.y;
        mag_sq = complex_mag_squared(z);
        iter++;
    }
    
    // smooth iteration count for better coloring
    float smooth_iter = 0.0f;
    if (iter < MAX_ITER) {
        smooth_iter = logf(logf(sqrtf(mag_sq))) / logf(2.0f);
    }
    
    // generate color and store in image
    Color color = get_color(iter, smooth_iter);
    image[y * width + x] = color;
}

// julia set kernel for variety
__global__ void julia_kernel(Color* image, int width, int height,
                            double julia_real, double julia_imag, double zoom) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x >= width || y >= height) return;
    
    double scale = 4.0 / (zoom * min(width, height));
    double real = (x - width / 2.0) * scale;
    double imag = (y - height / 2.0) * scale;
    
    float2 z = make_float2(real, imag);
    float2 c = make_float2(julia_real, julia_imag);
    
    int iter = 0;
    float mag_sq = 0.0f;
    
    while (iter < MAX_ITER && mag_sq < 16.0f) {
        z = complex_mul(z, z);
        z.x += c.x;
        z.y += c.y;
        mag_sq = complex_mag_squared(z);
        iter++;
    }
    
    float smooth_iter = 0.0f;
    if (iter < MAX_ITER) {
        smooth_iter = logf(logf(sqrtf(mag_sq))) / logf(2.0f);
    }
    
    Color color = get_color(iter, smooth_iter);
    image[y * width + x] = color;
}

// burning ship fractal kernel
__global__ void burning_ship_kernel(Color* image, int width, int height,
                                   double center_x, double center_y, double zoom) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x >= width || y >= height) return;
    
    double scale = 4.0 / (zoom * min(width, height));
    double real = center_x + (x - width / 2.0) * scale;
    double imag = center_y - (y - height / 2.0) * scale; // Note: flipped for burning ship
    
    float2 c = make_float2(real, imag);
    float2 z = make_float2(0.0f, 0.0f);
    
    int iter = 0;
    float mag_sq = 0.0f;
    
    while (iter < MAX_ITER && mag_sq < 16.0f) {
        // Burning Ship: z = (|Re(z)| + i|Im(z)|)^2 + c
        z.x = fabsf(z.x);
        z.y = fabsf(z.y);
        z = complex_mul(z, z);
        z.x += c.x;
        z.y += c.y;
        mag_sq = complex_mag_squared(z);
        iter++;
    }
    
    float smooth_iter = 0.0f;
    if (iter < MAX_ITER) {
        smooth_iter = logf(logf(sqrtf(mag_sq))) / logf(2.0f);
    }
    
    Color color = get_color(iter, smooth_iter);
    image[y * width + x] = color;
}

// save image as PPM format
void save_ppm(const char* filename, Color* image, int width, int height) {
    FILE* fp = fopen(filename, "wb");
    if (!fp) {
        printf("Error: Could not open file %s\n", filename);
        return;
    }
    
    fprintf(fp, "P6\n%d %d\n255\n", width, height);
    fwrite(image, sizeof(Color), width * height, fp);
    fclose(fp);
    printf("Saved fractal to %s\n", filename);
}

// main function with fractal generation examples
int main() {
    // allocate memory
    Color* h_image = (Color*)malloc(WIDTH * HEIGHT * sizeof(Color));
    Color* d_image;
    
    cudaMalloc(&d_image, WIDTH * HEIGHT * sizeof(Color));
    
    // CUDA grid configuration
    dim3 blockSize(16, 16);
    dim3 gridSize((WIDTH + blockSize.x - 1) / blockSize.x,
                  (HEIGHT + blockSize.y - 1) / blockSize.y);
    
    printf("Generating beautiful fractals with CUDA...\n");
    printf("Image size: %dx%d, Max iterations: %d\n", WIDTH, HEIGHT, MAX_ITER);
    
    // generate classic mandelbrot set
    printf("\n1. Generating Mandelbrot set...\n");
    mandelbrot_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, -0.5, 0.0, 1.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("mandelbrot_classic.ppm", h_image, WIDTH, HEIGHT);
    
    // generate zoomed mandelbrot
    printf("2. Generating zoomed Mandelbrot set...\n");
    mandelbrot_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, -0.7, 0.0, 100.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("mandelbrot_zoom.ppm", h_image, WIDTH, HEIGHT);
    
    // generate julia set variations
    printf("3. Generating Julia set (c = -0.7 + 0.27015i)...\n");
    julia_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, -0.7, 0.27015, 1.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("julia_1.ppm", h_image, WIDTH, HEIGHT);
    
    printf("4. Generating Julia set (c = -0.4 + 0.6i)...\n");
    julia_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, -0.4, 0.6, 1.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("julia_2.ppm", h_image, WIDTH, HEIGHT);
    
    printf("5. Generating Julia set (c = 0.285 + 0.01i)...\n");
    julia_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, 0.285, 0.01, 1.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("julia_3.ppm", h_image, WIDTH, HEIGHT);
    
    // generate burning ship fractal
    printf("6. Generating Burning Ship fractal...\n");
    burning_ship_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, -1.8, -0.08, 1.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("burning_ship.ppm", h_image, WIDTH, HEIGHT);
    
    // zoom into mandelbrot set
    printf("7. Generating deep zoom Mandelbrot...\n");
    mandelbrot_kernel<<<gridSize, blockSize>>>(d_image, WIDTH, HEIGHT, 
                                              -0.7269, 0.1889, 10000.0);
    cudaDeviceSynchronize();
    cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(Color), cudaMemcpyDeviceToHost);
    save_ppm("mandelbrot_deep_zoom.ppm", h_image, WIDTH, HEIGHT);
    
    // cleanup
    free(h_image);
    cudaFree(d_image);
    
    printf("\nAll fractals generated successfully!\n");
    
    return 0;
}
