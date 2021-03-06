#import <UIKit/UIKit.h>
#include "label.h"
#include <stdio.h>
#include <stdint.h>
#include <assert.h>

#import <sys/utsname.h>

void
font_create(int font_size, struct font_context *ctx) {
/*	for(NSString* family in [UIFont familyNames]) {
		NSLog(@"%@", family);
		for(NSString* name in [UIFont fontNamesForFamilyName: family]) {
			NSLog(@"  %@", name);
		}
	}*/
	UIFont* font = [UIFont fontWithName:@"STHeitiSC-Light" size:font_size];
	//	UIFont* font = [UIFont fontWithName:@"STHeitiSC-Medium" size:font_size];
	//UIFont* font = [UIFont fontWithName:@"FZLTHK--GBK1-0" size:font_size];
//	UIFont* font = [UIFont fontWithName:@"WenQuanYiMicroHei" size:font_size];
//	UIFont* font = [UIFont fontWithName:@"DFYuanW7-GBK" size:font_size];
	
//	UIFont* font = [UIFont fontWithName:@"HiraMinProN-W6" size:font_size];
  
	ctx->font = (__bridge void *)font;
  ctx->h = font.capHeight - font.descender;
  ctx->ascent = font.capHeight - font.ascender;
	ctx->dc = NULL;
}

void
font_release(struct font_context *ctx) {
}

void 
font_size(const char *str, int unicode, struct font_context *ctx) {
    NSString * tmp = [NSString stringWithUTF8String: str];
  
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
      CGSize constraint = CGSizeMake(NSUIntegerMax, NSUIntegerMax);
      NSDictionary *attributes = @{NSFontAttributeName: (__bridge UIFont *)ctx->font};
      CGRect rect = [tmp boundingRectWithSize:constraint options:NSStringDrawingUsesFontLeading attributes:attributes context:nil];
      CGSize sz = rect.size;
      
      ctx->w = (int)ceilf(sz.width);
    //  ctx->h = (int)ceilf(sz.height);
    } else {
      CGSize sz = [tmp sizeWithFont:(__bridge UIFont *)(ctx->font)];
  
      ctx->w = (int)sz.width;
    }
  
}

static void
dump(int w, int h, uint32_t *src) {
    static char map[] = "_123456789abcdef";
    int i,j;
    for (i=0;i<h;i++) {
        for (j=0;j<w;j++) {
            printf("%c",map[((src[w*i+j]>>24)&0xff)/16]);
        }
        printf("\n");
    }
    printf("\n");
    printf("\n");
    printf("\n");
}

static inline void
_font_glyph_gray(NSString* str, void* buffer, struct font_context* ctx){
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  CGContextRef context = CGBitmapContextCreate(buffer,
                                              (float)ctx->w,
                                              (float)ctx->h,
                                              8, (float)ctx->w,
                                              colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault);
  CGColorSpaceRelease(colorSpace);
  if(context == NULL){
    NSLog(@"the context is NULL! @ _font_glyph_gray function");
    
  }
  
  assert(context);
  CGContextTranslateCTM(context, 0, (float)ctx->h);
  CGContextScaleCTM(context, 1, -1);
  
   UIGraphicsPushContext(context);
  
  if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
    [str drawAtPoint:CGPointMake(0, ctx->ascent) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       (__bridge id)(ctx->font), NSFontAttributeName,
                                                       [UIColor colorWithWhite:1.0f alpha:1.0f],NSForegroundColorAttributeName,
                                                       nil]];
  }else{
    CGContextSetGrayFillColor(context, 1.0f, 1.0f);
    [str drawAtPoint:CGPointMake(0, ctx->ascent) withFont:(__bridge UIFont *)(ctx->font)];
  }
  UIGraphicsPopContext();
  CGContextRelease(context);
 //   dump(ctx->w, ctx->h, buffer);
}

//static inline void
//_test_write_ppm3(unsigned char* buffer, int w, int h){
//    static int count = 0;
//    NSMutableString* str = [[NSMutableString alloc] initWithFormat:@"P3\n%d %d\n255\n", w, h];
//    for(int i=0; i<w*h*4; i+=4){
//        [str appendFormat:@"%d ", buffer[i]];   // r
//        [str appendFormat:@"%d ", buffer[i+1]]; // g
//        [str appendFormat:@"%d ", buffer[i+2]];
//    }
//    
//    NSString* file = [NSString stringWithFormat:@"%@/Documents/font_%d.ppm", NSHomeDirectory(), count++];
//    [str writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];
//}

static void
convert_rgba_to_alpha(int sz, uint32_t * src, uint8_t *dest) {
	int i;
	for (i=0;i<sz;i++) {
		uint8_t alpha = (src[i]>>24) & 0xff;
//		uint8_t color = (src[i] >> 8) & 0xff;
		if (alpha == 0xff) {
//			dest[i] = color / 2 + 128;
      dest[i]=255;
		} else {
			dest[i] = alpha / 2;
		}
    //dest[i] = alpha;
	}
}


static inline void
_font_glyph_rgba(NSString* str, void* buffer, struct font_context* ctx){
    float w = (float)ctx->w;
    float h = (float)ctx->h;
    uint32_t tmp[ctx->w*ctx->h];
  memset(tmp,0,sizeof(tmp));
    UIFont* font = (__bridge id)(ctx->font);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate((void *)tmp, w, h, 8, w*4,
                                                 colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
  
    if(context == NULL){
        NSLog(@"the context is NULL! @ _font_glyph_rgba function ");
        CGColorSpaceRelease(colorSpace);
        return;
    }
    
    CGContextTranslateCTM(context, 0, h);
    CGContextScaleCTM(context, 1, -1);
    
    UIGraphicsPushContext(context);

    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
      
            CGContextSetLineWidth(context, 2);
            CGContextSetTextDrawingMode(context, kCGTextFillStroke);
            NSDictionary* _attr =[NSDictionary dictionaryWithObjectsAndKeys:
                              font, NSFontAttributeName,
 //                             [NSNumber numberWithFloat: -2.0], NSStrokeWidthAttributeName,
                              [UIColor whiteColor], NSForegroundColorAttributeName,
                              [UIColor blackColor], NSStrokeColorAttributeName,
                              nil];
            [str drawAtPoint:CGPointMake(1, 1) withAttributes:_attr];
//        
//            CGContextSetTextDrawingMode(context, kCGTextFill);
//            [str drawAtPoint:CGPointMake(2, 2) withAttributes:_attr];
      
    }
    else {
      
            CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        
            CGContextSetLineWidth(context, 4);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
            CGContextSetTextDrawingMode(context, kCGTextStroke);
            [str drawAtPoint:CGPointMake(2,2) withFont:font];
        
            CGContextSetTextDrawingMode(context, kCGTextFill);
            [str drawAtPoint:CGPointMake(2,2) withFont:font];
    }
    
    UIGraphicsPopContext();
    CGContextRelease(context);

	convert_rgba_to_alpha(ctx->w*ctx->h, tmp, buffer);
    
//    _test_write_ppm3(buffer, ctx->w, ctx->h);
}


void
font_glyph(const char * str, int unicode, void * buffer, struct font_context *ctx){
 
    NSString * tmp = [NSString stringWithUTF8String: str];
//    _font_glyph_rgba(tmp, buffer, ctx);
    _font_glyph_gray(tmp, buffer, ctx);
}


//void log_output(const char *format)
//{
//    NSString *str = [NSString stringWithUTF8String:format];
//    NSLog(@"%@", str);
//}
