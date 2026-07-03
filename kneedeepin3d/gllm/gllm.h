#ifndef GLLM_MATH

//#define GLLM_MATH

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

//Custom Types
typedef int16_t fixed16_t;
typedef int32_t fixed32_t;


#define BITS_PER_BYTE 8
#define BITS_PER_WORD 16

#define FRACTIONAL_SMALL_BITS 8
#define FRACTIONAL_SMALL_MAX 255
#define FRACTIONAL_SMALL_HALF 128
#define FRACTIONAL_SMALL_QUARTER 64
#define FIXED_SMALL_ONE (1 << BITS_PER_BYTE)
#define FIXED_ADD(a, b) ((a) + (b))
#define FIXED_SUB(a, b) ((a) - (b))
#define FIXED_SMALL_MUL(a, b) ((fixed16_t)(((int32_t)(a) * (int32_t)(b)) >> BITS_PER_BYTE))
#define INT_TO_SMALL_FIXED(i) ((fixed16_t)((i) << BITS_PER_BYTE))
#define FIXED16_TO_INT(f) ((f) >> BITS_PER_BYTE)
#define FIXED16_TO_FLOAT(f) ((float)(f) / (float)FIXED_SMALL_ONE)
#define MAKE_FIXED16(integ, frac_percent) ((fixed16_t)(((integ) << BITS_PER_BYTE) | (uint8_t)(((frac_percent << BITS_PER_BYTE) + 50) / 100)))

#define FRACTIONAL_LARGE_MAX 65535
#define FRACTIONAL_LARGE_HALF 32768
#define FRACTIONAL_LARGE_QUARTER 16384
#define FRACTIONAL_LARGE_BITS 16
#define FIXED_LARGE_ONE (1L << FRACTIONAL_LARGE_BITS)
#define FIXED_LARGE_MUL(a, b) ((fixed32_t)((int64_t)(a) * (int64_t)(b) >> FRACTIONAL_LARGE_BITS))
#define MAKE_FIXED32(integ, frac_percent) ((fixed32_t)(((uint32_t)(integ) << FRACTIONAL_LARGE_BITS ) | ((uint32_t)((frac_percent) * 65536 + 50) / 100 )))

#define INT_TO_LARGE_FIXED(i) ((fixed32_t)(((int64_t)(i) * 65536)))
#define FLOAT_TO_LARGE_FIXED(f) ((fixed32_t)((f) * 65536.0))
#define FIXED32_TO_INT(f) ((f) >> FRACTIONAL_LARGE_BITS)

//Broken
//#define FLOAT_TO_SMALL_FIXED(f) ((fixed16_t)((f) * FIXED_SMALL_ONE))
//#define FLOAT_TO_LARGE_FIXED(f) ((fixed32_t)((f) * FIXED_LARGE_ONE))
//#define FIXED32_TO_FLOAT(f) ((float)(f) / (float)FIXED_LARGE_ONE)

#define FIXED_LARGE_MUL_SMALL(a, b) ((fixed32_t)(((int64_t)(a) * (int64_t)(b)) >> BITS_PER_BYTE))

#define FULL_ROTATION_ANGLE 256

extern const fixed16_t sinTable[FULL_ROTATION_ANGLE];

//custom Structs

struct Vector2i {
    int16_t x;
    int16_t y;
};

struct Vector2ui {
    uint16_t x;
    uint8_t y;
};

struct Vector2uis {
    uint8_t x;
    uint8_t y;
};

struct Vector2uil {
    uint32_t x;
    uint32_t y;
};

struct Vector2li {
    int32_t x;
    int32_t y;
};

struct Vector2sf {
    fixed16_t x;
    fixed16_t y;
};

struct Vector2lf {
    fixed32_t x;
    fixed32_t y;
};

struct Vector3uis {
    uint8_t x;
    uint8_t y;
    uint8_t z;
};

struct Vector3i {
    int16_t x;
    int16_t y;
    int16_t z;
};

struct Vector3sf {
    fixed16_t x;
    fixed16_t y;
    fixed16_t z;
};

struct Vector3lf {
    fixed32_t x;
    fixed32_t y;
    fixed32_t z;
};

struct Edge {
    uint8_t to;
    uint8_t from;
};

struct Mesh3lf {
    struct Vector3lf* vertices;
    struct Edge* edges;
    uint16_t vertexCount;
    uint16_t edgeCount;
};

fixed16_t makeFixed16(const bool neg, const uint8_t integer, const uint8_t fractional);
fixed32_t makeFixed32(const bool neg, const uint16_t integer, const uint16_t fractional);
fixed32_t twosCompliment32(fixed32_t n);

fixed16_t fixed16div(fixed16_t a, fixed16_t b);
fixed32_t fixed16ToFixed32(fixed16_t v);
fixed32_t fixed32div(fixed32_t a, fixed32_t b);

uint8_t gllmRound(const fixed16_t v);
int16_t gllmSin(const uint8_t angle);
int16_t gllmCos(const uint8_t angle);

struct Vector2uis rotate2dVector(const struct Vector2uis vector, const fixed32_t angle);
struct Vector3lf translate3dVector(const struct Vector3lf vector, const struct Vector3lf offset);
struct Vector3lf rotate3dVectorX(const struct Vector3lf vector, const fixed32_t angle);
struct Vector3lf rotate3dVectorY(const struct Vector3lf vector, const fixed32_t angle);
struct Vector3lf rotate3dVectorZ(const struct Vector3lf vector, const fixed32_t angle);
struct Vector2sf projectSFvector(const struct Vector3sf point);
struct Vector2lf projectLFvector(const struct Vector3lf point);
struct Vector2i ndcToScreen(const struct Vector2uis dimensions, const struct Vector2lf ndc);

#endif