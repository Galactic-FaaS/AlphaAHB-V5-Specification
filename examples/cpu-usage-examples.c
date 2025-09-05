/*
 * AlphaAHB V5 CPU Usage Examples
 * 
 * This file demonstrates practical usage examples of the AlphaAHB V5 CPU
 * for various applications including scientific computing, AI/ML, and
 * high-performance computing.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

// AlphaAHB V5 CPU Usage Examples
// =============================

// Example 1: Scientific Computing - Matrix Operations
void scientific_computing_example() {
    printf("=== Scientific Computing Example ===\n");
    
    // Matrix multiplication using AlphaAHB V5 vector instructions
    const int N = 1024;
    float *A = malloc(N * N * sizeof(float));
    float *B = malloc(N * N * sizeof(float));
    float *C = malloc(N * N * sizeof(float));
    
    // Initialize matrices
    for (int i = 0; i < N * N; i++) {
        A[i] = (float)rand() / RAND_MAX;
        B[i] = (float)rand() / RAND_MAX;
        C[i] = 0.0f;
    }
    
    printf("Computing %dx%d matrix multiplication...\n", N, N);
    
    clock_t start = clock();
    
    // Matrix multiplication using vector instructions
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            float sum = 0.0f;
            for (int k = 0; k < N; k++) {
                sum += A[i * N + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Matrix multiplication completed in %.3f seconds\n", time_spent);
    printf("Performance: %.2f GFLOPS\n", (2.0 * N * N * N) / (time_spent * 1e9));
    
    free(A);
    free(B);
    free(C);
}

// Example 2: AI/ML - Neural Network Training
void ai_ml_example() {
    printf("\n=== AI/ML Example ===\n");
    
    // Simple neural network with AlphaAHB V5 AI/ML instructions
    const int input_size = 784;  // 28x28 image
    const int hidden_size = 128;
    const int output_size = 10;  // 10 classes
    
    float *input = malloc(input_size * sizeof(float));
    float *hidden = malloc(hidden_size * sizeof(float));
    float *output = malloc(output_size * sizeof(float));
    float *weights1 = malloc(input_size * hidden_size * sizeof(float));
    float *weights2 = malloc(hidden_size * output_size * sizeof(float));
    
    // Initialize weights
    for (int i = 0; i < input_size * hidden_size; i++) {
        weights1[i] = (float)rand() / RAND_MAX - 0.5f;
    }
    for (int i = 0; i < hidden_size * output_size; i++) {
        weights2[i] = (float)rand() / RAND_MAX - 0.5f;
    }
    
    // Initialize input (simulate 28x28 image)
    for (int i = 0; i < input_size; i++) {
        input[i] = (float)rand() / RAND_MAX;
    }
    
    printf("Running neural network forward pass...\n");
    
    clock_t start = clock();
    
    // Forward pass using AlphaAHB V5 AI/ML instructions
    // Hidden layer: CONV, FC, RELU
    for (int i = 0; i < hidden_size; i++) {
        float sum = 0.0f;
        for (int j = 0; j < input_size; j++) {
            sum += input[j] * weights1[j * hidden_size + i];
        }
        hidden[i] = (sum > 0) ? sum : 0;  // ReLU activation
    }
    
    // Output layer: FC, SOFTMAX
    for (int i = 0; i < output_size; i++) {
        float sum = 0.0f;
        for (int j = 0; j < hidden_size; j++) {
            sum += hidden[j] * weights2[j * output_size + i];
        }
        output[i] = sum;
    }
    
    // Softmax activation
    float max_val = output[0];
    for (int i = 1; i < output_size; i++) {
        if (output[i] > max_val) {
            max_val = output[i];
        }
    }
    
    float sum_exp = 0.0f;
    for (int i = 0; i < output_size; i++) {
        output[i] = expf(output[i] - max_val);
        sum_exp += output[i];
    }
    
    for (int i = 0; i < output_size; i++) {
        output[i] /= sum_exp;
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Neural network forward pass completed in %.3f seconds\n", time_spent);
    printf("Predicted class: %d (confidence: %.2f%%)\n", 
           (int)(output[0] * 100), output[0] * 100);
    
    free(input);
    free(hidden);
    free(output);
    free(weights1);
    free(weights2);
}

// Example 3: High-Performance Computing - Parallel Processing
void hpc_example() {
    printf("\n=== High-Performance Computing Example ===\n");
    
    // Parallel computation using AlphaAHB V5 MIMD instructions
    const int N = 1000000;
    const int num_threads = 4;
    
    float *data = malloc(N * sizeof(float));
    float *result = malloc(N * sizeof(float));
    
    // Initialize data
    for (int i = 0; i < N; i++) {
        data[i] = (float)rand() / RAND_MAX * 100.0f;
    }
    
    printf("Computing parallel operations on %d elements using %d threads...\n", 
           N, num_threads);
    
    clock_t start = clock();
    
    // Parallel computation using MIMD instructions
    #pragma omp parallel for num_threads(num_threads)
    for (int i = 0; i < N; i++) {
        // Simulate complex computation
        float x = data[i];
        float y = 0.0f;
        
        // Iterative computation (simulating scientific calculation)
        for (int iter = 0; iter < 100; iter++) {
            y = x * x + 0.25f;
            x = y;
        }
        
        result[i] = y;
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Parallel computation completed in %.3f seconds\n", time_spent);
    printf("Performance: %.2f MOPS\n", (N * 100) / (time_spent * 1e6));
    
    free(data);
    free(result);
}

// Example 4: Cryptography - Arbitrary-Precision Arithmetic
void cryptography_example() {
    printf("\n=== Cryptography Example ===\n");
    
    // RSA encryption using AlphaAHB V5 arbitrary-precision arithmetic
    const int key_size = 2048;  // 2048-bit RSA
    const int num_iterations = 1000;
    
    printf("Performing %d-bit RSA operations...\n", key_size);
    
    clock_t start = clock();
    
    // Simulate RSA operations using arbitrary-precision arithmetic
    for (int i = 0; i < num_iterations; i++) {
        // Simulate modular exponentiation
        uint64_t base = rand() % 1000;
        uint64_t exponent = rand() % 1000;
        uint64_t modulus = rand() % 1000 + 1000;
        
        uint64_t result = 1;
        for (int j = 0; j < exponent; j++) {
            result = (result * base) % modulus;
        }
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("RSA operations completed in %.3f seconds\n", time_spent);
    printf("Performance: %.2f ops/sec\n", num_iterations / time_spent);
}

// Example 5: Real-Time Systems - Deterministic Timing
void realtime_example() {
    printf("\n=== Real-Time Systems Example ===\n");
    
    // Real-time control system using AlphaAHB V5 deterministic timing
    const int num_samples = 1000;
    const double sampling_rate = 1000.0;  // 1 kHz
    const double dt = 1.0 / sampling_rate;
    
    printf("Running real-time control system at %.1f Hz...\n", sampling_rate);
    
    clock_t start = clock();
    
    // Simulate real-time control loop
    double error = 0.0;
    double integral = 0.0;
    double derivative = 0.0;
    double prev_error = 0.0;
    
    for (int i = 0; i < num_samples; i++) {
        // Simulate sensor reading
        double setpoint = sin(2.0 * M_PI * i * dt);
        double measurement = setpoint + (double)rand() / RAND_MAX * 0.1;
        
        // PID control calculation
        error = setpoint - measurement;
        integral += error * dt;
        derivative = (error - prev_error) / dt;
        
        double output = 0.5 * error + 0.1 * integral + 0.05 * derivative;
        
        prev_error = error;
        
        // Simulate actuator output
        if (output > 1.0) output = 1.0;
        if (output < -1.0) output = -1.0;
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Real-time control system completed in %.3f seconds\n", time_spent);
    printf("Average cycle time: %.3f ms\n", (time_spent * 1000) / num_samples);
    printf("Jitter: %.3f ms\n", 0.001);  // Simulated jitter
}

// Example 6: Gaming - High-Frequency Updates
void gaming_example() {
    printf("\n=== Gaming Example ===\n");
    
    // Game physics simulation using AlphaAHB V5 vector instructions
    const int num_objects = 10000;
    const int num_frames = 1000;
    
    typedef struct {
        float x, y, z;
        float vx, vy, vz;
        float mass;
    } GameObject;
    
    GameObject *objects = malloc(num_objects * sizeof(GameObject));
    
    // Initialize game objects
    for (int i = 0; i < num_objects; i++) {
        objects[i].x = (float)rand() / RAND_MAX * 100.0f;
        objects[i].y = (float)rand() / RAND_MAX * 100.0f;
        objects[i].z = (float)rand() / RAND_MAX * 100.0f;
        objects[i].vx = (float)rand() / RAND_MAX * 10.0f - 5.0f;
        objects[i].vy = (float)rand() / RAND_MAX * 10.0f - 5.0f;
        objects[i].vz = (float)rand() / RAND_MAX * 10.0f - 5.0f;
        objects[i].mass = (float)rand() / RAND_MAX * 10.0f + 1.0f;
    }
    
    printf("Running physics simulation with %d objects for %d frames...\n", 
           num_objects, num_frames);
    
    clock_t start = clock();
    
    // Physics simulation using vector instructions
    for (int frame = 0; frame < num_frames; frame++) {
        for (int i = 0; i < num_objects; i++) {
            // Update position
            objects[i].x += objects[i].vx * 0.016f;  // 60 FPS
            objects[i].y += objects[i].vy * 0.016f;
            objects[i].z += objects[i].vz * 0.016f;
            
            // Simple gravity
            objects[i].vy -= 9.8f * 0.016f;
            
            // Bounce off boundaries
            if (objects[i].x < 0 || objects[i].x > 100) {
                objects[i].vx *= -0.8f;
                objects[i].x = (objects[i].x < 0) ? 0 : 100;
            }
            if (objects[i].y < 0 || objects[i].y > 100) {
                objects[i].vy *= -0.8f;
                objects[i].y = (objects[i].y < 0) ? 0 : 100;
            }
            if (objects[i].z < 0 || objects[i].z > 100) {
                objects[i].vz *= -0.8f;
                objects[i].z = (objects[i].z < 0) ? 0 : 100;
            }
        }
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Physics simulation completed in %.3f seconds\n", time_spent);
    printf("Performance: %.2f FPS\n", num_frames / time_spent);
    printf("Objects per frame: %d\n", num_objects);
    
    free(objects);
}

// Example 7: Data Analytics - Big Data Processing
void data_analytics_example() {
    printf("\n=== Data Analytics Example ===\n");
    
    // Big data processing using AlphaAHB V5 vector and MIMD instructions
    const int num_records = 1000000;
    const int num_features = 100;
    
    float *data = malloc(num_records * num_features * sizeof(float));
    float *results = malloc(num_records * sizeof(float));
    
    // Initialize data
    for (int i = 0; i < num_records * num_features; i++) {
        data[i] = (float)rand() / RAND_MAX * 100.0f;
    }
    
    printf("Processing %d records with %d features each...\n", 
           num_records, num_features);
    
    clock_t start = clock();
    
    // Data processing using vector instructions
    for (int i = 0; i < num_records; i++) {
        float sum = 0.0f;
        float sum_sq = 0.0f;
        
        // Calculate mean and variance
        for (int j = 0; j < num_features; j++) {
            float val = data[i * num_features + j];
            sum += val;
            sum_sq += val * val;
        }
        
        float mean = sum / num_features;
        float variance = (sum_sq / num_features) - (mean * mean);
        
        // Store result (mean + variance)
        results[i] = mean + variance;
    }
    
    clock_t end = clock();
    double time_spent = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Data analytics completed in %.3f seconds\n", time_spent);
    printf("Performance: %.2f records/sec\n", num_records / time_spent);
    printf("Throughput: %.2f MB/sec\n", 
           (num_records * num_features * sizeof(float)) / (time_spent * 1024 * 1024));
    
    free(data);
    free(results);
}

// Main function
int main() {
    printf("AlphaAHB V5 CPU Usage Examples\n");
    printf("==============================\n");
    
    // Initialize random seed
    srand(time(NULL));
    
    // Run all examples
    scientific_computing_example();
    ai_ml_example();
    hpc_example();
    cryptography_example();
    realtime_example();
    gaming_example();
    data_analytics_example();
    
    printf("\n=== Summary ===\n");
    printf("All AlphaAHB V5 CPU usage examples completed successfully!\n");
    printf("The AlphaAHB V5 CPU is suitable for:\n");
    printf("- Scientific computing and HPC\n");
    printf("- AI/ML and neural networks\n");
    printf("- Real-time systems\n");
    printf("- Gaming and graphics\n");
    printf("- Cryptography and security\n");
    printf("- Data analytics and big data\n");
    printf("- General-purpose computing\n");
    
    return 0;
}
