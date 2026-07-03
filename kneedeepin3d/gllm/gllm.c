#include "gllm.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

//#define GLLM_DEBUG

const int16_t sinTable[256] = {
    0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92,
    97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176,
    181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234,
    236, 239, 241, 243, 245, 247, 248, 250, 251, 252, 253, 254, 255, 255, 255, 255,
    255, 255, 255, 255, 254, 253, 252, 251, 250, 248, 247, 245, 243, 241, 239, 236,
    234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181,
    176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97,
    92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6, 0,

    -6, -12, -18, -25, -31, -37, -43, -49, -56, -62, -68, -74, -80, -86, -92, -97,
    -103, -109, -115, -120, -126, -131, -136, -142, -147, -152, -157, -162, -167, -171, -176, -181,
    -185, -189, -193, -197, -201, -205, -209, -212, -216, -219, -222, -225, -228, -231, -234, -236,
    -239, -241, -243, -245, -247, -248, -250, -251, -252, -253, -254, -255, -255, -255, -255, -255,
    -255, -255, -255, -254, -253, -252, -251, -250, -248, -247, -245, -243, -241, -239, -236, -234,
    -231, -228, -225, -222, -219, -216, -212, -209, -205, -201, -197, -193, -189, -185, -181, -176,
    -171, -167, -162, -157, -152, -147, -142, -136, -131, -126, -120, -115, -109, -103, -97, -92,
    -86, -80, -74, -68, -62, -56, -49, -43, -37, -31, -25, -18, -12, -6, 0
};

#ifdef GLLM_DEBUG
void printVector2ui(const struct Vector2ui vector) {
    printf("%p: (%u, %u)\n", (void*) &vector, vector.x, vector.y);
}

void printVector2uis(const struct Vector2uis vector) {
    printf("%p: (%u, %u)\n", (void*) &vector, vector.x, vector.y);
}

void printVector2i(const struct Vector2i vector) {
    printf("%p: (%u, %u)\n", (void*) &vector, vector.x, vector.y);
}

uint16_t map(uint16_t x, uint16_t in_min, uint16_t in_max, uint16_t out_min, uint16_t out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
#endif

fixed16_t makeFixed16(const bool neg, const uint8_t integer, const uint8_t fractional) {
    fixed16_t result = integer << FRACTIONAL_SMALL_BITS;
    uint16_t fractionalPercent = (uint16_t)fractional;
    fractionalPercent <<= BITS_PER_BYTE; 
    fractionalPercent += 50;
    result |= (uint8_t) (fractionalPercent / 100);
    //if(neg == true) result = result * -1;
    return result;
}

fixed32_t makeFixed32(const bool neg, const uint16_t integer, const uint16_t fractional) {
    fixed32_t result = ((uint32_t)integer) << FRACTIONAL_LARGE_BITS;
    uint32_t fractionalPercent = (uint32_t)fractional;
    fractionalPercent <<= BITS_PER_WORD;
    result |= (uint16_t) (fractionalPercent / 100);
    //if(neg == true) result = result * -1;
    return result;
}

fixed32_t fixed16ToFixed32(fixed16_t v) {
    int8_t integer = (int8_t)(v >> 8);
    uint8_t fractional = (uint8_t)(v & 0xFF);
    return ((fixed32_t)integer << 16) | ((fixed32_t)fractional << 8);
}

fixed16_t fixed16div(fixed16_t a, fixed16_t b) {
    if (b == 0) return 0;
    int32_t numerator = (int32_t)a << FRACTIONAL_SMALL_BITS;
    int32_t denominator = (int32_t)b;
    int32_t result = numerator / denominator;
    return (fixed16_t)result;
}

fixed32_t fixed32div(fixed32_t a, fixed32_t b) {
    if (b == 0) return 0;
    long long numerator = (long long)a << FRACTIONAL_LARGE_BITS;
    long long denominator = (long long)b;
    long long result = numerator / denominator;
    return (fixed32_t)result;
}

fixed16_t gllmSin(uint8_t angle) {
    return sinTable[angle];
}

fixed16_t gllmCos(uint8_t angle) {
    uint8_t shiftedAngle = angle + FRACTIONAL_SMALL_QUARTER;
    return sinTable[shiftedAngle];
}

struct Vector2uis rotate2dVector(const struct Vector2uis vector, const fixed32_t angle) {
    return (struct Vector2uis) {
        vector.x * gllmCos(angle),
        vector.y * gllmSin(angle)
    };
}

struct Vector3lf translate3dVector(const struct Vector3lf vector, const struct Vector3lf offset) {
    return (struct Vector3lf) {
        FIXED_ADD(vector.x, offset.x),
        FIXED_ADD(vector.y, offset.y),
        FIXED_ADD(vector.z, offset.z)
    };
}

struct Vector3lf rotate3dVectorX(const struct Vector3lf vector, const fixed32_t angle) {
    fixed16_t cosAngle = gllmCos(angle);
    fixed16_t sinAngle = gllmSin(angle);
    struct Vector3lf result;
    result.x = vector.x;
    result.y = FIXED_LARGE_MUL_SMALL(vector.y, cosAngle) - FIXED_LARGE_MUL_SMALL(vector.z, sinAngle);
    result.z = FIXED_LARGE_MUL_SMALL(vector.y, sinAngle) + FIXED_LARGE_MUL_SMALL(vector.z, cosAngle);
    return result;
}

struct Vector3lf rotate3dVectorY(const struct Vector3lf vector, fixed32_t angle) {
    fixed16_t cosAngle = gllmCos(angle);
    fixed16_t sinAngle = gllmSin(angle);
    struct Vector3lf result;
    result.x = FIXED_LARGE_MUL_SMALL(vector.x, cosAngle) - FIXED_LARGE_MUL_SMALL(vector.z, sinAngle);
    result.y = vector.y;
    result.z = FIXED_LARGE_MUL_SMALL(vector.x, sinAngle) + FIXED_LARGE_MUL_SMALL(vector.z, cosAngle);
    return result;
}

struct Vector3lf rotate3dVectorZ(const struct Vector3lf vector, const fixed32_t angle) {
    fixed16_t cosAngle = gllmCos(angle);
    fixed16_t sinAngle = gllmSin(angle);
    struct Vector3lf result;
    result.x = FIXED_LARGE_MUL_SMALL(vector.x, cosAngle) - FIXED_LARGE_MUL_SMALL(vector.y, sinAngle);
    result.y = FIXED_LARGE_MUL_SMALL(vector.x, sinAngle) + FIXED_LARGE_MUL_SMALL(vector.y, cosAngle);
    result.z = vector.z;
    return result;
}

struct Vector2sf projectSFvector(const struct Vector3sf point) {
    return (struct Vector2sf) {fixed16div(point.x, point.z), fixed16div(point.y, point.z)};
}

struct Vector2lf projectLFvector(const struct Vector3lf point) {
    struct Vector2lf result = {fixed32div(point.x, point.z), fixed32div(point.y, point.z)};
    return result;
}

struct Vector2i ndcToScreen(const struct Vector2uis dimensions, const struct Vector2lf ndc) {
    struct Vector2i  screenCoordinates;
    int32_t stage1x = FIXED_ADD(ndc.x, INT_TO_LARGE_FIXED(1));
    int32_t stage1y = FIXED_ADD(ndc.y, INT_TO_LARGE_FIXED(1));
    int32_t stage2x = FIXED_LARGE_MUL(stage1x, INT_TO_LARGE_FIXED(dimensions.x));
    int32_t stage2y = FIXED_LARGE_MUL(stage1y, INT_TO_LARGE_FIXED(dimensions.y));
    int32_t stage3x = stage2x >> 1;
    int32_t stage3y = stage2y >> 1;
    screenCoordinates.x = FIXED32_TO_INT(stage3x);
    screenCoordinates.y = FIXED32_TO_INT(stage3y);

    #ifdef GLLM_DEBUG
    if(screenCoordinates.x >= dimensions.x) {
        printf("xOverflow with ");
        printVector2i(screenCoordinates);
        screenCoordinates.x = dimensions.x -1;
    }
    if(screenCoordinates.y >= dimensions.y) {
        printf("yOverflow with ");
        printVector2i(screenCoordinates);
        screenCoordinates.y = dimensions.y -1;
    }
    if(screenCoordinates.x < 0) {
        printf("xUnderflow with ");
        printVector2i(screenCoordinates);
    }
    if(screenCoordinates.y < 0) {
        printf("yUnderflow with ");
        printVector2i(screenCoordinates);
        screenCoordinates.y = 0;
    }
    #endif
    return screenCoordinates;
}