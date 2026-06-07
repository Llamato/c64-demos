#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "../gllm/gllm.h"

//Memory Mapping Macros
#define ADDRESS_TO_PTR(ADDR) ((volatile unsigned char*)ADDR)

//Memory mappings
#define VIC_BORDER_COLOR		0xD020
#define VIC_BACKGROUND_COLOR 	0xD021
#define TEXT_SCREEN      		0x0400
#define SCREEN_COLOR_RAM		0xD800
#define SPRITES_ENABLE   		0xD015
#define SPRITE_0_PTR     		0x07f8
#define SPRITE_1_PTR     		0x07f9
#define SPRITE_2_PTR     		0x07fa
#define SPRITE_3_PTR     		0x07fb
#define SPRITE_4_PTR     		0x07fc
#define SPRITE_5_PTR     		0x07fd
#define SPRITE_6_PTR     		0x07fe
#define SPRITE_7_PTR     		0x07ff
#define SPRITES_X_HIGH 			0xD010
#define SPRITE_0_COLOR 			0xD027
#define SPRITE_1_COLOR 			0xD028
#define SPRITE_2_COLOR 			0xD029
#define SPRITE_3_COLOR 			0xD02A
#define SPRITE_4_COLOR 			0xD02B
#define SPRITE_5_COLOR 			0xD02C
#define SPRITE_6_COLOR 			0xD02D
#define SPRITE_7_COLOR 			0xD02E

#define SPRITE_0_POSITION 0xD000

#define HARDWARE_SPRITE_COUNT 8
#define SPRITE_SIZE 64
#define SPRITE_BITMAP_ADDRESS(SPRITE_BLOCK) (SPRITE_BLOCK * SPRITE_SIZE)
#define POINT_SPRITE(SPRITE_NR, BLOCK) *ADDRESS_TO_PTR(SPRITE_##SPRITE_NR##_PTR) = SPRITE_##BLOCK##_FRONTBUFFER_BLOCK;
#define SET_BIT(BYTE_ADDR, BIT_NR) *ADDRESS_TO_PTR(BYTE_ADDR) | (1<<BIT_NR)
#define CLEAR_BIT(BYTE_ADDR, BIT_NR) *ADDRESS_TO_PTR(BYTE_ADDR) & ~(1<<BIT_NR)
#define ENABLE_SPRITE(SPRITE_NR) SET_BIT(SPRITES_ENABLE, SPRITE_NR)
#define DISABLE_SPRITE(SPRITE_NR) CLEAR_BIT(SPRITES_ENABLE, SPRITE_NR)

#define SPRITE_0_FRONTBUFFER_BLOCK 252
#define SPRITE_0_BACKBUFFER_BLOCK 253

#define SPRITE_1_FRONTBUFFER_BLOCK 254
#define SPRITE_1_BACKBUFFER_BLOCK 255

#define SPRITE_2_FRONTBUFFER_BLOCK 237
#define SPRITE_2_BACKBUFFER_BLOCK 238

#define SPRITE_3_FRONTBUFFER_BLOCK 210
#define SPRITE_3_BACKBUFFER_BLOCK 211

#define SPRITE_4_FRONTBUFFER_BLOCK 212
#define SPRITE_4_BACKBUFFER_BLOCK 213

#define SPRITE_5_FRONTBUFFER_BLOCK 216
#define SPRITE_5_BACKBUFFER_BLOCK 217

#define SPRITE_6_FRONTBUFFER_BLOCK 224
#define SPRITE_6_BACKBUFFER_BLOCK 225

#define SPRITE_7_FRONTBUFFER_BLOCK 240
#define SPRITE_7_BACKBUFFER_BLOCK 241

//Hardware limitations
#define BITS_PER_BYTE 8
#define SPRITE_COLUMNS 24
#define SPRITE_ROWS 21
#define SPRITE_BYTES_PER_ROW SPRITE_COLUMNS / BITS_PER_BYTE
#define COLOR_BLACK 0
#define COLOR_WHITE 1
#define COLOR_RED 2
#define COLOR_CYAN 3
#define COLOR_VIOLET 4
#define COLOR_GREEN 5
#define COLOR_BLUE 6
#define COLOR_YELLOW 7
#define COLOR_ORANGE 8
#define COLOR_BROWN 9
#define COLOR_LIGHT_RED 10
#define COLOR_DARK_GRAY 11
#define COLOR_GRAY 12
#define COLOR_LIGHT_GREEN 13
#define COLOR_LIGHT_BLUE 14
#define COLOR_LIGHT_GRAY 15

#define GLLM_DEBUG

struct BufferPair {
    uint8_t frontBufferBlock;
    uint8_t backBufferBlock;
};

struct BitmapPosition {
    uint16_t byte;
    uint8_t bit;
};

struct Object3lf {
    struct Vector3lf position;
    struct Vector3uis rotation;
    struct Mesh3lf mesh;
};

struct SpriteBase {
    struct Vector2ui position;
    uint8_t color;
    volatile unsigned char* bitmapPtr;
};

struct Sprite3d {
    struct SpriteBase sprite;
    struct Object3lf* object;
};

void fillMemory(volatile unsigned char* memoryPtr, uint16_t length, uint8_t fillByte) {
	for(uint16_t currentByte = 0; currentByte < length; currentByte++) {
		memoryPtr[currentByte] = fillByte;
	}
}

volatile unsigned char* bitmapPtrFromSpriteBlock(uint8_t block) {
    uint16_t addressValue = block * SPRITE_SIZE;
    return (volatile unsigned char*) addressValue;
}

struct BitmapPosition spritePixelPositionToBitmapPosition(const struct Vector2uis position) {
    const uint16_t bitPosition = position.y * SPRITE_BYTES_PER_ROW * BITS_PER_BYTE + position.x;
    struct BitmapPosition bitmapPosition = { bitPosition / BITS_PER_BYTE, bitPosition % 8};
    return bitmapPosition;
}

void setSpritePixel(volatile unsigned char* bitmapPointer, const struct Vector2uis position) {
    struct BitmapPosition bitmapPosition = spritePixelPositionToBitmapPosition(position);
    bitmapPointer[bitmapPosition.byte] |= (1<<((BITS_PER_BYTE - 1) - bitmapPosition.bit)); 
}

void makeLineSpriteBresenham(volatile unsigned char* bitmapPointer, const struct Vector2uis origin, const struct Vector2uis destination) {
    int16_t x0 = origin.x;
    int16_t y0 = origin.y;
    int16_t x1 = destination.x;
    int16_t y1 = destination.y;
    int16_t dx = abs(x1 - x0);
    int16_t dy = abs(y1 - y0);
    int16_t sx = (x0 < x1) ? 1 : -1;
    int16_t sy = (y0 < y1) ? 1 : -1;
    int16_t err = dx - dy;
    int16_t x = x0;
    int16_t y = y0;
    while(1) {
        if (x >= 0 && x < SPRITE_COLUMNS && y >= 0 && y < SPRITE_ROWS) {
            setSpritePixel(bitmapPointer, (struct Vector2uis) {x, y});
        }
        if (x == x1 && y == y1) break;
        int16_t e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x += sx;
        }
        if (e2 < dx) {
            err += dx;
            y += sy;
        }
    }
}

void spritePointsFromVertexArray(struct Vector2uis* results, const struct Vector3lf* vertices, uint16_t vertexCount) {
    const struct Vector2uis spriteDimensions = {SPRITE_COLUMNS, SPRITE_ROWS};
    for(uint16_t currentVertexIndex = 0; currentVertexIndex < vertexCount; currentVertexIndex++) {
        const struct Vector3lf currentVertex = vertices[currentVertexIndex];
        const struct Vector2lf currentVertexProjection = projectLFvector(currentVertex);
        const struct Vector2i currentVertexScreenCoordinates = ndcToScreen(spriteDimensions, currentVertexProjection);
        results[currentVertexIndex].x = currentVertexScreenCoordinates.x;
        results[currentVertexIndex].y = currentVertexScreenCoordinates.y;
    }
}

void makePointCloudMeshSprite(volatile unsigned char* bitmapPointer, const struct Mesh3lf* mesh) {
    const struct Vector2uis spriteDimensions = {SPRITE_COLUMNS, SPRITE_ROWS};
    for(uint16_t currentVertexIndex = 0; currentVertexIndex < mesh->vertexCount; currentVertexIndex++) {
        const struct Vector3lf currentVertex = mesh->vertices[currentVertexIndex];
        const struct Vector2lf currentVertexProjection = projectLFvector(currentVertex);
        const struct Vector2i currentVertexScreenCoordinates = ndcToScreen(spriteDimensions, currentVertexProjection);
        setSpritePixel(bitmapPointer, (struct Vector2uis) {currentVertexScreenCoordinates.x, currentVertexScreenCoordinates.y});
    }
}

void makeWireframeMeshSprite(volatile unsigned char* bitmapPointer, const struct Mesh3lf* mesh) {
    const struct Vector2uis spriteDimensions = {SPRITE_COLUMNS, SPRITE_ROWS};
    struct Vector2uis twoDpoints[mesh->vertexCount];
    spritePointsFromVertexArray(twoDpoints, mesh->vertices, mesh->vertexCount);
    for(uint16_t currentEdgeIndex = 0; currentEdgeIndex < mesh->edgeCount; currentEdgeIndex++) {
        const struct Edge currentEdge = mesh->edges[currentEdgeIndex];
        const struct Vector2uis lineOrigin = twoDpoints[currentEdge.from];
        const struct Vector2uis lineDestination = twoDpoints[currentEdge.to];
        makeLineSpriteBresenham(bitmapPointer, (struct Vector2uis) {lineOrigin.x, lineOrigin.y}, (struct Vector2uis) {lineDestination.x, lineDestination.y});
    }
}

void positionSprite(const uint8_t spriteNr, const struct Vector2ui posiition) {
    volatile unsigned char* spriteXlowPositionRegisterAddress = ADDRESS_TO_PTR(SPRITE_0_POSITION + spriteNr * 2);
    uint8_t positionXlow = posiition.x & 0xFF;
    bool positionXhigh = posiition.y & 0x100;
    *spriteXlowPositionRegisterAddress = positionXlow;
    *ADDRESS_TO_PTR(SPRITES_X_HIGH) = (SPRITES_X_HIGH & ~(1 << spriteNr) | (positionXhigh << spriteNr));
    volatile unsigned char* spriteYpositionRegisterAddress = spriteXlowPositionRegisterAddress+1;
    *spriteYpositionRegisterAddress = posiition.y;
}

void colorSprite(const uint8_t spriteNr, const uint8_t color) {
    volatile unsigned char* spriteColors = ADDRESS_TO_PTR(SPRITE_0_COLOR);
    spriteColors[spriteNr] = color;
}

uint8_t getSpriteBlock(const uint8_t spriteNr) {
    volatile unsigned char* spriteBlockPointers = ADDRESS_TO_PTR(SPRITE_0_FRONTBUFFER_BLOCK);
    return spriteBlockPointers[spriteNr];
}

void setSpriteBlock(const uint8_t spriteNr, const uint8_t block) {
    volatile unsigned char* spriteBlockPointers = ADDRESS_TO_PTR(SPRITE_0_FRONTBUFFER_BLOCK);
    spriteBlockPointers[spriteNr] = block;
}

void copySpriteBitmap(volatile unsigned char* to, volatile unsigned char* from) {
	for(uint16_t currentByte = 0; currentByte < SPRITE_SIZE; currentByte++) {
		to[currentByte] = from[currentByte];
	}
}

void copyByteArray(unsigned char* to, const unsigned char* from, uint16_t size) {
    for(uint16_t currentByte = 0; currentByte < size; currentByte++) {
        to[currentByte] = from[currentByte];
    }
}

volatile unsigned char* backbufferBitmapPtrs[] = {
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_0_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_1_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_2_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_3_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_4_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_5_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_6_BACKBUFFER_BLOCK)),
    ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_7_BACKBUFFER_BLOCK))
};

struct BufferPair bufferBlocks[] = {
    {SPRITE_0_FRONTBUFFER_BLOCK, SPRITE_0_BACKBUFFER_BLOCK},
    {SPRITE_1_FRONTBUFFER_BLOCK, SPRITE_1_BACKBUFFER_BLOCK},
    {SPRITE_2_FRONTBUFFER_BLOCK, SPRITE_2_BACKBUFFER_BLOCK},
    {SPRITE_3_FRONTBUFFER_BLOCK, SPRITE_3_BACKBUFFER_BLOCK},
    {SPRITE_4_FRONTBUFFER_BLOCK, SPRITE_4_BACKBUFFER_BLOCK},
    {SPRITE_5_FRONTBUFFER_BLOCK, SPRITE_5_BACKBUFFER_BLOCK},
    {SPRITE_6_FRONTBUFFER_BLOCK, SPRITE_6_BACKBUFFER_BLOCK},
    {SPRITE_7_FRONTBUFFER_BLOCK, SPRITE_7_BACKBUFFER_BLOCK}
};

void rotate3dSprite(struct Sprite3d *s3d, const uint8_t angle) {
    for(uint32_t currentVertex = 0; currentVertex < s3d->object->mesh.vertexCount; currentVertex++) {
        s3d->object->mesh.vertices[currentVertex] = rotateVectorY(s3d->object->mesh.vertices[currentVertex], angle);
    }
}

void translate3dSprite(struct Sprite3d *s3d, const struct Vector3lf position) {
    for(uint32_t currentVertex = 0; currentVertex < s3d->object->mesh.vertexCount; currentVertex++) {
        s3d->object->mesh.vertices[currentVertex] = translateVector(s3d->object->mesh.vertices[currentVertex], position);
    }
    //s3d->object->position = positio; //Preserve position
}

void swapSpriteWithBackbuffer(const uint8_t spriteNr, struct SpriteBase* sprite) {
    uint8_t tempBlock = bufferBlocks[spriteNr].backBufferBlock;
    bufferBlocks[spriteNr].backBufferBlock = bufferBlocks[spriteNr].frontBufferBlock;
    bufferBlocks[spriteNr].frontBufferBlock = tempBlock;
    volatile unsigned char* tempBitmapPtr = sprite->bitmapPtr;
    sprite->bitmapPtr = backbufferBitmapPtrs[spriteNr];
    backbufferBitmapPtrs[spriteNr] = tempBitmapPtr;
}

struct Vector3lf* spriteVertexBuffers[HARDWARE_SPRITE_COUNT];
void draw3dSprite(uint8_t hwSpriteSlot, struct Sprite3d *s3d) {
    swapSpriteWithBackbuffer(hwSpriteSlot, &s3d->sprite);
    fillMemory(s3d->sprite.bitmapPtr, SPRITE_SIZE, 0x00);
    copyByteArray((unsigned char*) spriteVertexBuffers[hwSpriteSlot], (unsigned char*) s3d->object->mesh.vertices, s3d->object->mesh.vertexCount * sizeof(struct Vector3lf));
    struct Vector3lf* templatePtr = s3d->object->mesh.vertices;
    s3d->object->mesh.vertices = spriteVertexBuffers[hwSpriteSlot];
    rotate3dSprite(s3d, s3d->object->rotation.y);
    translate3dSprite(s3d, s3d->object->position);
    makeWireframeMeshSprite(s3d->sprite.bitmapPtr, &s3d->object->mesh);
    s3d->object->mesh.vertices = templatePtr;
    //swapSpriteWithBackbuffer(hwSpriteSlot, &s3d->sprite);
}

int main(void) {
    //Background colors
    *ADDRESS_TO_PTR(VIC_BACKGROUND_COLOR) = COLOR_BLACK;
    *ADDRESS_TO_PTR(VIC_BORDER_COLOR) = COLOR_GRAY;

    //Enable sprites
    *ADDRESS_TO_PTR(SPRITES_ENABLE) = 0xff;
    POINT_SPRITE(0, 0);
    POINT_SPRITE(1, 1);
    POINT_SPRITE(2, 2);
    POINT_SPRITE(3, 3);
    POINT_SPRITE(4, 4);
    POINT_SPRITE(5, 5);
    POINT_SPRITE(6, 6);
    POINT_SPRITE(7, 7);

    //Debug!!!
    positionSprite(7, (struct Vector2ui) {160, 100});
    *ADDRESS_TO_PTR(SPRITE_7_COLOR) = COLOR_WHITE;

    //d4
    struct Vector3lf tetrahedronVertices[] = {
    {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1)},
    {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1)},
    {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1)},
    {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1)}
    };
    struct Edge tetrahedronEdges[] = {
    {0, 1}, {0, 2}, {0, 3},  // Top to base edges
    {1, 2}, {2, 3}, {3, 1}   // Base triangle
    };
    struct Object3lf tetrahedronObject = {
        (struct Vector3lf){INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0), MAKE_FIXED32(2, 50)},
        {0, 0, 0},
        (struct Mesh3lf) {tetrahedronVertices, tetrahedronEdges, sizeof(tetrahedronVertices) / sizeof(struct Vector3lf), sizeof(tetrahedronEdges) / sizeof(struct Edge)}
    };
    struct Sprite3d tetrahedronSprite = {
        (struct SpriteBase) {(struct Vector2ui) {120, 200}, COLOR_RED, ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_0_FRONTBUFFER_BLOCK))},
        &tetrahedronObject
    };
    struct Vector3lf tetrahedronVertexBuffer[sizeof(tetrahedronVertices) / sizeof(struct Vector3lf)];
    spriteVertexBuffers[0] = tetrahedronVertexBuffer;

    //d6
    struct Vector3lf cubeVertices[] = {
        // Front face (z = +1.0)
        {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1)},
        {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1)},
        {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1)},
        {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1)},
        
        // Back face (z = -1.0)
        {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1)},
        {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1)},
        {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(-1)},
        {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(-1)},
    };
    struct Edge cubeEdges[] = {
        // Front face (vertices 0-3)
        {0, 1},  // left front
        {0, 2},  // bottom front
        {1, 3},  // top front
        {2, 3},  // right front
        
        // Back face (vertices 4-7)
        {4, 5},  // left back
        {4, 6},  // bottom back
        {5, 7},  // top back
        {6, 7},  // right back
        
        // Connecting edges between front and back
        {0, 4},  // bottom-left
        {1, 5},  // top-left
        {2, 6}, // bottom-right
        {3, 7}  // top-right
    };
    struct Object3lf cubeObject = {
        (struct Vector3lf) {INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0), MAKE_FIXED32(2, 50)}, 
        {0, 0, 0},
        (struct Mesh3lf) { cubeVertices, cubeEdges, sizeof(cubeVertices) / sizeof(struct Vector3lf), sizeof(cubeEdges) / sizeof(struct Edge)},
    };
    struct Sprite3d cubeSprite = {
        (struct SpriteBase) {(struct Vector2ui) {160, 200}, COLOR_WHITE, ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_1_FRONTBUFFER_BLOCK))},
        &cubeObject
    };
    struct Vector3lf cubeVertexBuffer[sizeof(cubeVertices) / sizeof(struct Vector3lf)];
    spriteVertexBuffers[1] = cubeVertexBuffer;


    //d8
    struct Vector3lf octahedronVertices[] = {
    // Top and bottom (the tips)
    {INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(0)},   // Top tip
    {INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(0)},  // Bottom tip
    
    // Middle square (equator)
    {INT_TO_LARGE_FIXED(1), INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0)},   // Right
    {INT_TO_LARGE_FIXED(-1), INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0)},  // Left
    {INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(1)},   // Front
    {INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(-1)}   // Back
    };
    struct Edge octahedronEdges[] = {
        // Top tip to all middle vertices (4 edges)
        {0, 2}, {0, 3}, {0, 4}, {0, 5},
        
        // Bottom tip to all middle vertices (4 edges)
        {1, 2}, {1, 3}, {1, 4}, {1, 5},
        
        // Middle square edges (4 edges - forms a diamond/square)
        {2, 4}, {4, 3}, {3, 5}, {5, 2}
    };
    struct Object3lf octahedronObject = {
        (struct Vector3lf){INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(0), MAKE_FIXED32(1, 50)},
        {0, 0, 0},
        (struct Mesh3lf) {octahedronVertices, octahedronEdges, sizeof(octahedronVertices) / sizeof(struct Vector3lf), sizeof(octahedronEdges) / sizeof(struct Edge)}
    };
    struct Sprite3d octahedronSprite = {
        (struct SpriteBase) {(struct Vector2ui) {200, 200}, COLOR_CYAN, ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_2_FRONTBUFFER_BLOCK))},
        &octahedronObject
    };
    struct Vector3lf octahedronVertexBuffer[sizeof(octahedronVertices) / sizeof(struct Vector3lf)];
    spriteVertexBuffers[2] = octahedronVertexBuffer;

    //d12
    struct Vector3lf dodecahedronVertices[] = {
        // (±5, ±5, ±5) - cube vertices
        {INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED( 5)},
        {INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED(-5)},
        {INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED( 5)},
        {INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED(-5)},
        {INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED( 5)},
        {INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED( 5), INT_TO_LARGE_FIXED(-5)},
        {INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED( 5)},
        {INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED(-5), INT_TO_LARGE_FIXED(-5)},
        
        // (0, ±3, ±8) - 4 vertices (since 5/φ ≈ 3, 5*φ ≈ 8)
        {INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED( 3), INT_TO_LARGE_FIXED( 8)},
        {INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED( 3), INT_TO_LARGE_FIXED(-8)},
        {INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED(-3), INT_TO_LARGE_FIXED( 8)},
        {INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED(-3), INT_TO_LARGE_FIXED(-8)},
        
        // (±3, ±8, 0) - 4 vertices
        {INT_TO_LARGE_FIXED( 3), INT_TO_LARGE_FIXED( 8), INT_TO_LARGE_FIXED( 0)},
        {INT_TO_LARGE_FIXED( 3), INT_TO_LARGE_FIXED(-8), INT_TO_LARGE_FIXED( 0)},
        {INT_TO_LARGE_FIXED(-3), INT_TO_LARGE_FIXED( 8), INT_TO_LARGE_FIXED( 0)},
        {INT_TO_LARGE_FIXED(-3), INT_TO_LARGE_FIXED(-8), INT_TO_LARGE_FIXED( 0)},
        
        // (±8, 0, ±3) - 4 vertices
        {INT_TO_LARGE_FIXED( 8), INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED( 3)},
        {INT_TO_LARGE_FIXED( 8), INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED(-3)},
        {INT_TO_LARGE_FIXED(-8), INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED( 3)},
        {INT_TO_LARGE_FIXED(-8), INT_TO_LARGE_FIXED( 0), INT_TO_LARGE_FIXED(-3)}
    };
    struct Edge dodecahedronEdges[] = {
        // Cube edges (8 cube vertices)
        {0, 1}, {0, 2}, {0, 4},
        {1, 3}, {1, 5},
        {2, 3}, {2, 6},
        {3, 7},
        {4, 5}, {4, 6},
        {5, 7},
        {6, 7},
        
        // Connections to middle-layer vertices (simplified - you'll need all)
        {0, 8}, {0, 12}, {0, 16},
        {1, 9}, {1, 13}, {1, 17},
        {2, 10}, {2, 12}, {2, 16},
        {3, 11}, {3, 13}, {3, 17},
        {4, 8}, {4, 14}, {4, 18},
        {5, 9}, {5, 15}, {5, 19},
        {6, 10}, {6, 14}, {6, 18},
        {7, 11}, {7, 15}, {7, 19},
        
        // Pentagon edges (connecting middle vertices)
        {8, 9}, {8, 14}, {9, 15}, {10, 11}, {10, 16},
        {11, 17}, {12, 13}, {12, 18}, {13, 19}, {14, 15},
        {16, 17}, {18, 19}
    };
    struct Object3lf dodecahedronObject = {
        (struct Vector3lf){INT_TO_LARGE_FIXED(0), INT_TO_LARGE_FIXED(-110), INT_TO_LARGE_FIXED(110)},
        {0, 0, 0},
        (struct Mesh3lf) {dodecahedronVertices, dodecahedronEdges, sizeof(dodecahedronVertices) / sizeof(struct Vector3lf), sizeof(dodecahedronEdges) / sizeof(struct Edge)}
    };
    struct Sprite3d dodecahedronSprite = {
        (struct SpriteBase) {(struct Vector2ui) {240, 200}, COLOR_VIOLET, ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_2_FRONTBUFFER_BLOCK))},
        &dodecahedronObject
    };
    struct Vector3lf dodecahedronVertexBuffer[sizeof(dodecahedronVertices) / sizeof(struct Vector3lf)];
    spriteVertexBuffers[3] = dodecahedronVertexBuffer;

    uint8_t spriteBackbufferBlocks[HARDWARE_SPRITE_COUNT];
    struct Sprite3d* sprites[] = {&tetrahedronSprite, &cubeSprite, &octahedronSprite, &dodecahedronSprite};
    const uint8_t spriteCount = sizeof(sprites) / sizeof(struct Sprite3d*);
    for(uint8_t currentSprite = 0; currentSprite < spriteCount; currentSprite++) {
        positionSprite(currentSprite, sprites[currentSprite]->sprite.position);
        colorSprite(currentSprite, sprites[currentSprite]->sprite.color);
    }
    
    bool gamerunning = true;
    while(gamerunning) {
        for(uint8_t currentSprite = 0; currentSprite < spriteCount; currentSprite++) {
            sprites[currentSprite]->object->rotation.y++;
            draw3dSprite(currentSprite, sprites[currentSprite]);
        }
    }
}