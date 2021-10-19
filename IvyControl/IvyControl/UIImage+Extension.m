//
//  UIImage+Extension.m
//  ImageDither
//
//  Created by zwwuchn on 8/5/19.
//  Copyright © 2019 zwwuchn. All rights reserved.
//

//  Modified By Whittle iGEM 2021


#import "UIImage+Extension.h"

@implementation UIImage (Extension)

#pragma mark - 图片抖动处理
- (UIImage *)dithered {
    UIImage *resultImage;
    // 分配内存
    const int imageWidth = self.size.width;
    const int imageHeight = self.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* oldImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    uint32_t* newImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();// 色彩范围的容器
    CGContextRef oldContext = CGBitmapContextCreate(oldImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(oldContext, CGRectMake(0, 0, imageWidth, imageHeight), self.CGImage);
    
    CGContextRef newContext = CGBitmapContextCreate(newImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(newContext, CGRectMake(0, 0, imageWidth, imageHeight), self.CGImage);
        // 遍历像素
        int pixelNum = imageWidth * imageHeight;
        uint32_t* pCurPtr = oldImageBuf;
        uint32_t* newCurPtr = newImageBuf;
    
        for (int i = 0; i < pixelNum; i++, pCurPtr++)
        {
            int row = i / imageWidth ;
            int column = i % imageWidth;
            uint8_t* ptr = (uint8_t*)pCurPtr;
            uint8_t r = ptr[3];
            uint8_t g = ptr[2];
            uint8_t b = ptr[1];
            uint8_t nearColor = [self getNearstColor:r g:g b:b];
            uint8_t* newptr = (uint8_t*)newCurPtr;
            //残差
            int eRgb[3];
            if (nearColor == 0) {
                newptr[3] = 0;
                newptr[2] = 0;
                newptr[1] = 0;
                newptr[0] = 255;
                eRgb[0] = r;
                eRgb[1] = g;
                eRgb[2] = b;
            } else {
                newptr[3] = 255;
                newptr[2] = 255;
                newptr[1] = 255;
                newptr[0] = 255;
                eRgb[0] = r-255;
                eRgb[1] = g-255;
                eRgb[2] = b-255;
            }
            //残差 16分之 7、5、3、1
            float rate1 = 0.4375;
            float rate2 = 0.3125;
            float rate3 = 0.1875;
            float rate4 = 0.0625;
            uint32_t rgb1 = [self getPixel:oldImageBuf width:imageWidth height:imageHeight row:row column:column+1 rate:rate1 eRgb:eRgb];
            uint32_t rgb2 = [self getPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column rate:rate2 eRgb:eRgb];
            uint32_t rgb3 = [self getPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column-1 rate:rate3 eRgb:eRgb];
            uint32_t rgb4 = [self getPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column+1 rate:rate4 eRgb:eRgb];
            [self setPixel:oldImageBuf width:imageWidth height:imageHeight row:row column:column+1 value:rgb1];
            [self setPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column value:rgb2];
            [self setPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column-1 value:rgb3];
            [self setPixel:oldImageBuf width:imageWidth height:imageHeight row:row+1 column:column+1 value:rgb4];
            newCurPtr++;
        }
    
    // 将内存转成image
    CGDataProviderRef dataProvider =CGDataProviderCreateWithData(NULL, newImageBuf, bytesPerRow * imageHeight, nil);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight,8, 32, bytesPerRow, colorSpace,kCGImageAlphaLast |kCGBitmapByteOrder32Little, dataProvider,NULL,true,kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    resultImage = [UIImage imageWithCGImage:imageRef];
    
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(oldContext);
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    return resultImage;
}
#pragma mark- 获取相邻像素值
- (int )getNearstColor:(uint8_t) r g:(uint8_t) g b:(uint8_t) b {
    int distance0Squared = pow(r, 2) + pow(g, 2) + pow(b, 2);
    int distance255Squared = pow((255-r), 2) + pow((255-g), 2) + pow((255-b), 2);
    if (distance0Squared < distance255Squared) {
        return 0;
    } else {
        return 1;
    }
}
#pragma mark- 获取像素点
- (uint32_t)getPixel:(uint32_t*)imageBuf width:(int)width height:(int)height   row:(int)row column:(int)column rate:(float)rate eRgb:(int *)eRgb {
    if (row < 0 || row >= height || column < 0 || column >= width) {
        return 0xFFFFFFFF;
    }
    int index = row * width + column;
    uint32_t *ptr = imageBuf + index;
    uint8_t* newptr = (uint8_t*)ptr;
    uint8_t r = newptr[3];
    uint8_t g = newptr[2];
    uint8_t b = newptr[1];
    uint8_t a = newptr[0];
    int er = eRgb[0];
    int eg = eRgb[1];
    int eb = eRgb[2];
    r = clamp(r + (int)(rate*er));
    g = clamp(g + (int)(rate*eg));
    b = clamp(b + (int)(rate*eb));
    return (r << 24) + (g << 16) + (b << 8) + a;
}
#pragma mark - 设置像素点
- (void)setPixel:(uint32_t*)imageBuf width:(int)width height:(int)height   row:(int)row column:(int)column value:(uint32_t)value {
    if (row < 0 || row >= height || column < 0 || column >= width) {
        return;
    }
    int index = row * width + column;
    uint32_t *ptr = imageBuf + index;
    uint8_t* newptr = (uint8_t*)ptr;
    int r = (value & 0xFF000000) >> 24;
    int g = (value & 0x00FF0000) >> 16;
    int b = (value & 0x0000FF00) >> 8;
    int a = value & 0x000000FF;
    
    newptr[3] = r;
    newptr[2] = g;
    newptr[1] = b;
    newptr[0] = a;
}

int clamp(int value) {
    return value > 255 ? 255 : (value < 0 ? 0: value);
}


// MARK: Fixed Threshold
- (UIImage *)binarized {
    
    CGSize size =[self size];
    int width =size.width;
    int height =size.height;
    
    //像素将画在这个数组
    uint32_t *pixels = (uint32_t *)malloc(width *height *sizeof(uint32_t));
    //清空像素数组
    memset(pixels, 0, width*height*sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //用 pixels 创建一个 context
    CGContextRef context =CGBitmapContextCreate(pixels, width, height, 8, width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);
    
    int tt =1;
    CGFloat intensity;
    int bw;
    
    for (int y = 0; y <height; y++) {
        for (int x =0; x <width; x ++) {
            uint8_t *rgbaPixel = (uint8_t *)&pixels[y*width+x];
            intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;
            
            bw = intensity > 0.45?255:0;
            
            rgbaPixel[tt] = bw;
            rgbaPixel[tt + 1] = bw;
            rgbaPixel[tt + 2] = bw;
            
        }
    }
 
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

- (UIImage *)negative
{
    // get width and height as integers, since we'll be using them as
    // array subscripts, etc, and this'll save a whole lot of casting
    CGSize size = self.size;
    int width = size.width;
    int height = size.height;

    // Create a suitable RGB+alpha bitmap context in BGRA colour space
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *memoryPool = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);

    // draw the current image to the newly created context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);

    // run through every pixel, a scan line at a time...
    for(int y = 0; y < height; y++)
    {
        // get a pointer to the start of this scan line
        unsigned char *linePointer = &memoryPool[y * width * 4];

        // step through the pixels one by one...
        for(int x = 0; x < width; x++)
        {
            // get RGB values. We're dealing with premultiplied alpha
            // here, so we need to divide by the alpha channel (if it
            // isn't zero, of course) to get uninflected RGB. We
            // multiply by 255 to keep precision while still using
            // integers
            int r, g, b;
            if(linePointer[3])
            {
                r = linePointer[0] * 255 / linePointer[3];
                g = linePointer[1] * 255 / linePointer[3];
                b = linePointer[2] * 255 / linePointer[3];
            }
            else
                r = g = b = 0;

            // perform the colour inversion
            r = 255 - r;
            g = 255 - g;
            b = 255 - b;

            if ( (r+g+b) / (3*255) == 0 )
            {

                linePointer[0] = linePointer[1] = linePointer[2] = 0;
                linePointer[3] = 0;
            }
            else
            {
                // multiply by alpha again, divide by 255 to undo the
                // scaling before, store the new values and advance
                // the pointer we're reading pixel data from
                linePointer[0] = r * linePointer[3] / 255;
                linePointer[1] = g * linePointer[3] / 255;
                linePointer[2] = b * linePointer[3] / 255;

            }
            linePointer += 4;
        }
    }

    // get a CG image from the context, wrap that into a
    // UIImage
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];

    // clean up
    CGImageRelease(cgImage);
    CGContextRelease(context);
    free(memoryPool);

    // and return
    return returnImage;
}

@end

//    Apache License
//    Version 2.0, January 2004
//    http://www.apache.org/licenses/
//
//    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
//
//    1. Definitions.
//
//    "License" shall mean the terms and conditions for use, reproduction,
//    and distribution as defined by Sections 1 through 9 of this document.
//
//    "Licensor" shall mean the copyright owner or entity authorized by
//    the copyright owner that is granting the License.
//
//    "Legal Entity" shall mean the union of the acting entity and all
//    other entities that control, are controlled by, or are under common
//    control with that entity. For the purposes of this definition,
//    "control" means (i) the power, direct or indirect, to cause the
//    direction or management of such entity, whether by contract or
//    otherwise, or (ii) ownership of fifty percent (50%) or more of the
//    outstanding shares, or (iii) beneficial ownership of such entity.
//
//    "You" (or "Your") shall mean an individual or Legal Entity
//    exercising permissions granted by this License.
//
//    "Source" form shall mean the preferred form for making modifications,
//    including but not limited to software source code, documentation
//    source, and configuration files.
//
//    "Object" form shall mean any form resulting from mechanical
//    transformation or translation of a Source form, including but
//    not limited to compiled object code, generated documentation,
//    and conversions to other media types.
//
//    "Work" shall mean the work of authorship, whether in Source or
//    Object form, made available under the License, as indicated by a
//    copyright notice that is included in or attached to the work
//    (an example is provided in the Appendix below).
//
//    "Derivative Works" shall mean any work, whether in Source or Object
//    form, that is based on (or derived from) the Work and for which the
//    editorial revisions, annotations, elaborations, or other modifications
//    represent, as a whole, an original work of authorship. For the purposes
//    of this License, Derivative Works shall not include works that remain
//    separable from, or merely link (or bind by name) to the interfaces of,
//    the Work and Derivative Works thereof.
//
//    "Contribution" shall mean any work of authorship, including
//    the original version of the Work and any modifications or additions
//    to that Work or Derivative Works thereof, that is intentionally
//    submitted to Licensor for inclusion in the Work by the copyright owner
//    or by an individual or Legal Entity authorized to submit on behalf of
//    the copyright owner. For the purposes of this definition, "submitted"
//    means any form of electronic, verbal, or written communication sent
//    to the Licensor or its representatives, including but not limited to
//    communication on electronic mailing lists, source code control systems,
//    and issue tracking systems that are managed by, or on behalf of, the
//    Licensor for the purpose of discussing and improving the Work, but
//    excluding communication that is conspicuously marked or otherwise
//    designated in writing by the copyright owner as "Not a Contribution."
//
//    "Contributor" shall mean Licensor and any individual or Legal Entity
//    on behalf of whom a Contribution has been received by Licensor and
//    subsequently incorporated within the Work.
//
//    2. Grant of Copyright License. Subject to the terms and conditions of
//    this License, each Contributor hereby grants to You a perpetual,
//    worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//    copyright license to reproduce, prepare Derivative Works of,
//    publicly display, publicly perform, sublicense, and distribute the
//    Work and such Derivative Works in Source or Object form.
//
//    3. Grant of Patent License. Subject to the terms and conditions of
//    this License, each Contributor hereby grants to You a perpetual,
//    worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//    (except as stated in this section) patent license to make, have made,
//    use, offer to sell, sell, import, and otherwise transfer the Work,
//    where such license applies only to those patent claims licensable
//    by such Contributor that are necessarily infringed by their
//    Contribution(s) alone or by combination of their Contribution(s)
//    with the Work to which such Contribution(s) was submitted. If You
//    institute patent litigation against any entity (including a
//    cross-claim or counterclaim in a lawsuit) alleging that the Work
//    or a Contribution incorporated within the Work constitutes direct
//    or contributory patent infringement, then any patent licenses
//    granted to You under this License for that Work shall terminate
//    as of the date such litigation is filed.
//
//    4. Redistribution. You may reproduce and distribute copies of the
//    Work or Derivative Works thereof in any medium, with or without
//    modifications, and in Source or Object form, provided that You
//    meet the following conditions:
//
//    (a) You must give any other recipients of the Work or
//    Derivative Works a copy of this License; and
//
//    (b) You must cause any modified files to carry prominent notices
//    stating that You changed the files; and
//
//    (c) You must retain, in the Source form of any Derivative Works
//    that You distribute, all copyright, patent, trademark, and
//    attribution notices from the Source form of the Work,
//    excluding those notices that do not pertain to any part of
//    the Derivative Works; and
//
//    (d) If the Work includes a "NOTICE" text file as part of its
//    distribution, then any Derivative Works that You distribute must
//    include a readable copy of the attribution notices contained
//    within such NOTICE file, excluding those notices that do not
//    pertain to any part of the Derivative Works, in at least one
//    of the following places: within a NOTICE text file distributed
//    as part of the Derivative Works; within the Source form or
//    documentation, if provided along with the Derivative Works; or,
//    within a display generated by the Derivative Works, if and
//    wherever such third-party notices normally appear. The contents
//    of the NOTICE file are for informational purposes only and
//    do not modify the License. You may add Your own attribution
//    notices within Derivative Works that You distribute, alongside
//    or as an addendum to the NOTICE text from the Work, provided
//    that such additional attribution notices cannot be construed
//    as modifying the License.
//
//    You may add Your own copyright statement to Your modifications and
//    may provide additional or different license terms and conditions
//    for use, reproduction, or distribution of Your modifications, or
//    for any such Derivative Works as a whole, provided Your use,
//    reproduction, and distribution of the Work otherwise complies with
//    the conditions stated in this License.
//
//    5. Submission of Contributions. Unless You explicitly state otherwise,
//    any Contribution intentionally submitted for inclusion in the Work
//    by You to the Licensor shall be under the terms and conditions of
//    this License, without any additional terms or conditions.
//    Notwithstanding the above, nothing herein shall supersede or modify
//    the terms of any separate license agreement you may have executed
//    with Licensor regarding such Contributions.
//
//    6. Trademarks. This License does not grant permission to use the trade
//    names, trademarks, service marks, or product names of the Licensor,
//    except as required for reasonable and customary use in describing the
//    origin of the Work and reproducing the content of the NOTICE file.
//
//    7. Disclaimer of Warranty. Unless required by applicable law or
//    agreed to in writing, Licensor provides the Work (and each
//    Contributor provides its Contributions) on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
//    implied, including, without limitation, any warranties or conditions
//    of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
//    PARTICULAR PURPOSE. You are solely responsible for determining the
//    appropriateness of using or redistributing the Work and assume any
//    risks associated with Your exercise of permissions under this License.
//
//    8. Limitation of Liability. In no event and under no legal theory,
//    whether in tort (including negligence), contract, or otherwise,
//    unless required by applicable law (such as deliberate and grossly
//    negligent acts) or agreed to in writing, shall any Contributor be
//    liable to You for damages, including any direct, indirect, special,
//    incidental, or consequential damages of any character arising as a
//    result of this License or out of the use or inability to use the
//    Work (including but not limited to damages for loss of goodwill,
//    work stoppage, computer failure or malfunction, or any and all
//    other commercial damages or losses), even if such Contributor
//    has been advised of the possibility of such damages.
//
//    9. Accepting Warranty or Additional Liability. While redistributing
//    the Work or Derivative Works thereof, You may choose to offer,
//    and charge a fee for, acceptance of support, warranty, indemnity,
//    or other liability obligations and/or rights consistent with this
//    License. However, in accepting such obligations, You may act only
//    on Your own behalf and on Your sole responsibility, not on behalf
//    of any other Contributor, and only if You agree to indemnify,
//    defend, and hold each Contributor harmless for any liability
//    incurred by, or claims asserted against, such Contributor by reason
//    of your accepting any such warranty or additional liability.
//
//    END OF TERMS AND CONDITIONS
//
//    APPENDIX: How to apply the Apache License to your work.
//
//    To apply the Apache License to your work, attach the following
//    boilerplate notice, with the fields enclosed by brackets "[]"
//    replaced with your own identifying information. (Don't include
//    the brackets!)  The text should be enclosed in the appropriate
//    comment syntax for the file format. We also recommend that a
//    file or class name and description of purpose be included on the
//    same "printed page" as the copyright notice for easier
//    identification within third-party archives.
//
//    Copyright 2021 wuzhenweichn
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
