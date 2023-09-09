[TOC]

# 关键词

## DYNAMICLIGHTMAP_ON

- 当物体的GI来源为LightMap

  ![image-20230907113910733](.Assets/.URP-PBR%E7%9D%80%E8%89%B2%E5%99%A8%E8%B1%86%E7%9F%A5%E8%AF%86-%E5%85%B3%E9%94%AE%E8%AF%8D/image-20230907113910733.png)

- 同时在Lighting中开启Realtime Global Illumination

  ![image-20230907114033228](.Assets/.URP-PBR%E7%9D%80%E8%89%B2%E5%99%A8%E8%B1%86%E7%9F%A5%E8%AF%86-%E5%85%B3%E9%94%AE%E8%AF%8D/image-20230907114033228.png)

- 此时```Generate Lighting```后, 该关键词才会激活

- 考虑到移动端的性能, 暂时去掉该功能, 以简化PBR基础着色器.