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
#define POINT_SPRITE(SPRITE_NR, BLOCK) *ADDRESS_TO_PTR(SPRITE_##SPRITE_NR##_PTR) = SPRITE_##BLOCK##_BLOCK;
#define SET_BIT(BYTE_ADDR, BIT_NR) *ADDRESS_TO_PTR(BYTE_ADDR) | (1<<BIT_NR)
#define CLEAR_BIT(BYTE_ADDR, BIT_NR) *ADDRESS_TO_PTR(BYTE_ADDR) & ~(1<<BIT_NR)
#define ENABLE_SPRITE(SPRITE_NR) SET_BIT(SPRITES_ENABLE, SPRITE_NR)
#define DISABLE_SPRITE(SPRITE_NR) CLEAR_BIT(SPRITES_ENABLE, SPRITE_NR)

#define SPRITE_0_BLOCK 252
#define SPRITE_1_BLOCK 253
#define SPRITE_2_BLOCK 208
#define SPRITE_3_BLOCK 208
#define SPRITE_4_BLOCK 208
#define SPRITE_5_BLOCK 216
#define SPRITE_6_BLOCK 224
#define SPRITE_7_BLOCK 240

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
struct BitmapPosition {
    uint16_t byte;
    uint8_t bit;
};

struct Object3lf {
    struct Vector3lf position;
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

uint8_t getSpriteBlock(const uint8_t spriteNr) {
    volatile unsigned char* spriteBlockPointers = ADDRESS_TO_PTR(SPRITE_0_BLOCK);
    return spriteBlockPointers[spriteNr];
}

void setSpriteBlock(const uint8_t spriteNr, const uint8_t block) {
    volatile unsigned char* spriteBlockPointers = ADDRESS_TO_PTR(SPRITE_0_BLOCK);
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

volatile unsigned char* backbufferBitmapPtr = ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_7_BLOCK));
void swapSpriteWithBackbuffer(const uint8_t spriteNr, struct SpriteBase* sprite) {
    uint8_t backbufferBlock = getSpriteBlock(7);
    uint8_t tempBlock = getSpriteBlock(spriteNr);
    setSpriteBlock(spriteNr, backbufferBlock);
    setSpriteBlock(7, tempBlock);
    volatile unsigned char* tempBitmapPtr = sprite->bitmapPtr;
    sprite->bitmapPtr = backbufferBitmapPtr;
    backbufferBitmapPtr = tempBitmapPtr;
}

uint8_t framecounter = 0;
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
    positionSprite(7, (struct Vector2ui) {160, 200});
    *ADDRESS_TO_PTR(SPRITE_7_COLOR) = COLOR_WHITE;

    //Setup sprites
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
        (struct Mesh3lf) { cubeVertices, cubeEdges, sizeof(cubeVertices) / sizeof(struct Vector3lf), sizeof(cubeEdges) / sizeof(struct Edge)}
    };
    struct Sprite3d cubeSprite = {
        (struct SpriteBase)  {(struct Vector2ui) {160, 200}, COLOR_BLUE, ADDRESS_TO_PTR(SPRITE_BITMAP_ADDRESS(SPRITE_0_BLOCK))},
        &cubeObject
    };
    struct Sprite3d* sprites[] = {&cubeSprite};
    const uint8_t spriteCount = sizeof(sprites) / sizeof(struct Sprite3d*);
    struct Vector3lf* spriteVertexBuffers[HARDWARE_SPRITE_COUNT];
    for(uint8_t currentSprite = 0; currentSprite < spriteCount; currentSprite++) {
        positionSprite(currentSprite, sprites[currentSprite]->sprite.position);
        spriteVertexBuffers[currentSprite] = malloc(sprites[currentSprite]->object->mesh.vertexCount * sizeof(struct Vector3lf));
    }
    
    bool gamerunning = true;
    while(gamerunning) {
        for(uint8_t currentSprite = 0; currentSprite < spriteCount; currentSprite++) {
            swapSpriteWithBackbuffer(currentSprite, &sprites[currentSprite]->sprite);
            fillMemory(sprites[currentSprite]->sprite.bitmapPtr, SPRITE_SIZE, 0x00);
            copyByteArray((unsigned char*) spriteVertexBuffers[currentSprite], (unsigned char*) sprites[currentSprite]->object->mesh.vertices, sprites[currentSprite]->object->mesh.vertexCount * sizeof(struct Vector3lf));
            struct Vector3lf* templatePtr = sprites[currentSprite]->object->mesh.vertices;
            sprites[currentSprite]->object->mesh.vertices = spriteVertexBuffers[currentSprite];
            for(uint32_t currentVertex = 0; currentVertex < sprites[currentSprite]->object->mesh.vertexCount; currentVertex++) {
                sprites[currentSprite]->object->mesh.vertices[currentVertex] = rotateVectorY(sprites[currentSprite]->object->mesh.vertices[currentVertex], framecounter);
                sprites[currentSprite]->object->mesh.vertices[currentVertex] = translateVector(sprites[currentSprite]->object->mesh.vertices[currentVertex], sprites[currentSprite]->object->position);
            }
            makeWireframeMeshSprite(sprites[currentSprite]->sprite.bitmapPtr, &sprites[currentSprite]->object->mesh);
            sprites[currentSprite]->object->mesh.vertices = templatePtr;
            framecounter++;
        }
    }
    
    for(uint8_t currentBuffer = 0; currentBuffer < spriteCount; currentBuffer++) {
        free(spriteVertexBuffers[currentBuffer]);
    }
}