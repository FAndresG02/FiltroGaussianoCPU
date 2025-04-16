#define STB_IMAGE_IMPLEMENTATION 
#include "C:\\Users\\andre\\Documents\\COMPUTACION_PARALELA\\Librerias\\stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "C:\\Users\\andre\\Documents\\COMPUTACION_PARALELA\\Librerias\\stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define KERNEL_SIZE 21
#define OFFSET (KERNEL_SIZE / 2)

// Genera un kernel gaussiano con tamaño y sigma especificados
void generarKernelGaussiano(float* kernel, int kernelSize, float sigma) {
    float sum = 0.0f;
    int offset = kernelSize / 2;

    // Recorre cada posición del kernel
    for (int y = -offset; y <= offset; y++) {
        for (int x = -offset; x <= offset; x++) {
            // Calcula el valor gaussiano para la posición (x, y)
            float exponent = -(x * x + y * y) / (2.0f * sigma * sigma);
            float value = expf(exponent) / (2.0f * M_PI * sigma * sigma);
            kernel[(y + offset) * kernelSize + (x + offset)] = value;
            sum += value; // Acumula la suma para normalizar
        }
    }

    // Normaliza el kernel para que la suma total sea 1
    for (int i = 0; i < kernelSize * kernelSize; i++) {
        kernel[i] /= sum;
    }
}

// Aplica el filtro gaussiano sobre una imagen en escala de grises
void aplicarFiltroGaussianoCPU(unsigned char* input, unsigned char* output, int width, int height, float* kernel) {
    // Recorre cada píxel de la imagen
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            float sum = 0.0f;

            // Aplica la convolución con el kernel gaussiano
            for (int ky = -OFFSET; ky <= OFFSET; ky++) {
                for (int kx = -OFFSET; kx <= OFFSET; kx++) {
                    // Calcula la posición del píxel vecino
                    int px = x + kx;
                    int py = y + ky;

                    // Aplica bordes reflejados para evitar acceder fuera de la imagen
                    if (px < 0) px = 0;
                    if (py < 0) py = 0;
                    if (px >= width) px = width - 1;
                    if (py >= height) py = height - 1;

                    // Obtiene el valor del píxel y su peso en el kernel
                    float pixel = (float)input[py * width + px];
                    float weight = kernel[(ky + OFFSET) * KERNEL_SIZE + (kx + OFFSET)];
                    sum += pixel * weight; // Acumula el valor ponderado
                }
            }

            // Asigna el nuevo valor al píxel en la imagen de salida
            output[y * width + x] = (unsigned char)fminf(fmaxf(sum, 0.0f), 255.0f);
        }
    }
}

int main() {
    int width, height, channels;

    // Carga una imagen en escala de grises
    unsigned char* gray = stbi_load("C:/Users/andre/Documents/TRABAJO/Tarea en clase - Filtro/img.jpg", &width, &height, &channels, 1);
    if (!gray) {
        printf("No se pudo cargar la imagen.\n");
        return -1;
    }

    // Reserva memoria para la imagen de salida
    size_t imageSize = width * height * sizeof(unsigned char);
    unsigned char* result = (unsigned char*)malloc(imageSize);
    if (!result) {
        printf("No se pudo asignar memoria para la imagen de salida.\n");
        stbi_image_free(gray);
        return -1;
    }

    // Genera el kernel gaussiano
    float h_kernel[KERNEL_SIZE * KERNEL_SIZE];
    float sigma = 3.5f; // Puedes ajustar este valor para cambiar la intensidad del desenfoque
    generarKernelGaussiano(h_kernel, KERNEL_SIZE, sigma);

    // Mide el tiempo de ejecución del filtro
    clock_t start = clock();
    aplicarFiltroGaussianoCPU(gray, result, width, height, h_kernel);
    clock_t end = clock();

    double elapsedTime = 1000.0 * (end - start) / CLOCKS_PER_SEC;

    // Guarda la imagen filtrada
    if (stbi_write_jpg("C:/Users/andre/Documents/21CPU.jpg", width, height, 1, result, 100)) {
        printf("Imagen JPG guardada correctamente.\n");
    }
    else {
        printf("Error al guardar la imagen JPG.\n");
    }

    printf("Filtro gaussiano aplicado en CPU.\n");
    printf("Tiempo total de ejecución: %.2f ms\n", elapsedTime);

    // Libera la memoria utilizada
    stbi_image_free(gray);
    free(result);

    return 0;
}
