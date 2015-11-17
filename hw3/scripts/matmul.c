#include <stdio.h>
#include <stdlib.h>

static void populate_matrix(int[], const int, const int);
static void matrix_multiply(int[], int[], int[], const int);

int main() {
    static const int N = 8;
    static const int LIMIT = 128;

    int A[N*N], B[N*N], C[N*N];
    int i, j;

    FILE *a_file = fopen("a.txt", "w");
    FILE *b_file = fopen("b.txt", "w");
    FILE *c_file = fopen("c.txt", "w");

    populate_matrix(A, N, LIMIT);
    populate_matrix(B, N, LIMIT);
    matrix_multiply(A, B, C, N);

    for (i = 0; i < N; i++) {
      for (j = 0; j < N; j++) {
        fprintf(a_file, "%08x\n", A[i*N + j]);
        fprintf(b_file, "%08x\n", B[i*N + j]);
        fprintf(c_file, "%08x\n", C[i*N + j]);
      }
    }

    return 0;
}

static void populate_matrix(int M[], const int N, const int LIMIT) {
    int i, j;
    
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            M[i*N + j] = rand() % LIMIT;
        }
    }
}

static void matrix_multiply(int A[], int B[], int C[], const int N) {
    int i, j, k;

    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            C[i*N + j] = 0;
            for (k = 0; k < N; k++) {
                C[i*N + j] += A[i*N + k] * B[k*N + j];
            }
        }
    }
}

