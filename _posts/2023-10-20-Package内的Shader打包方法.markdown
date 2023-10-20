---
layout: post
title: "Package内的Shader打包方法"
categories: [Unity, Package]
tags: Unity Package AssetBundle
math: true
---

# Package内的Shader打包方法

## 00 前言

通常的打包方式是采用将工程中的资源设置好AssetBundle名称和扩展名的方式, 再使用:

public static [AssetBundleManifest](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleManifest.html) **BuildAssetBundles** (string **outputPath**, [BuildAssetBundleOptions](https://docs.unity.cn/cn/2023.1/ScriptReference/BuildAssetBundleOptions.html) **assetBundleOptions**, [BuildTarget](https://docs.unity.cn/cn/2023.1/ScriptReference/BuildTarget.html) **targetPlatform**);

命令进行打包. 其中:

| 参数               | 意义                     |
| ------------------ | ------------------------ |
| outputPath         | AssetBundle 的输出路径。 |
| assetBundleOptions | 资源包构建选项。         |
| targetPlatform     | 选择的目标构建平台。     |

[AssetBundle 工作流程 - Unity 手册](https://docs.unity.cn/cn/2023.1/Manual/AssetBundles-Workflow.html)

![image-20231020114247563](/assets/image/image-20231020114247563.png)

而Package中的资源无法在面板上输入AssetBundle的名称和扩展名.

## 01 处理方法-打包

对于Package内的资源, Unity提供了一个```BuildAssetBundles```方法的重载可以进行打包. 重载如下:

public static [AssetBundleManifest](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleManifest.html) **BuildAssetBundles** (string **outputPath**, AssetBundleBuild[] **builds**, [BuildAssetBundleOptions](https://docs.unity.cn/cn/2023.1/ScriptReference/BuildAssetBundleOptions.html) **assetBundleOptions**, [BuildTarget](https://docs.unity.cn/cn/2023.1/ScriptReference/BuildTarget.html) **targetPlatform**);

相比之前的方法, 此重载多了一个```AssetBundleBuild[]```来记录AssetBundle的信息, 而不是依赖资源上的名称和扩展名.

关于[AssetBundleBuild ](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleBuild.html), 首先是一个结构体, 其包含的变量如下

| 变量                                                         | 意义                              |
| ------------------------------------------------------------ | --------------------------------- |
| [addressableNames](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleBuild-addressableNames.html) | 用于加载资源的可寻址名称。        |
| [assetBundleName](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleBuild-assetBundleName.html) | AssetBundle 名称。                |
| [assetBundleVariant](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleBuild-assetBundleVariant.html) | AssetBundle 变体。                |
| [assetNames](https://docs.unity.cn/cn/2023.1/ScriptReference/AssetBundleBuild-assetNames.html) | 属于给定 AssetBundle 的资源名称。 |

assetBundleName即AssetBundle名称部分, 也就是等价于之前我们在面板上输入的```cube```, assetBundleVariant即扩展名部分, assetNames即该AsstBundle包中所有资源的路径, 而addressableNames可以理解为对包中资源的重命名, 如果留空的话, 会直接使用assetNames本身.

此时采用类似下方的测试代码就可以进行打包操作了, 此时注意打包的平台是```Android```, 所以后续的加载需要将Unity的启动参数设置为```-force-gles```才可以正常使用```Android```的着色器.

```c++
public class Make
{
    [MenuItem("MyTools/Make")]
    public static void MakeAB()
    {
        var buildMap = new AssetBundleBuild[2];//声明一个AssetBundleBuild的数值用于记录AssetBundle包的信息, 此时为了测试直接声明了长度为2的数组, 实际操作的适合可以用List比较灵活, 然后转为数组即可.

        buildMap[0].assetBundleName = "mat";//第一个包打包材质球, 该包的名字
        buildMap[0].assetNames = new string[] { "Assets/Material/TreeMat.mat" };//具体包中包含的材质球路径

        buildMap[1].assetBundleName = "shader";//第二个包打包着色器, 该包的名字
        buildMap[1].assetNames = new string[] { "Packages/com.render.environment/Shaders/Tree/Tree_Lit_Release_10.shader" };//具体包中包含的着色器路径, 这里可以看出该着色器就在Package中
        
        BuildPipeline.BuildAssetBundles(Application.streamingAssetsPath, buildMap, BuildAssetBundleOptions.StrictMode, BuildTarget.Android);//打包命令.

    }
}
```

## 02 处理方法-加载

因为只是测试, 所以做了一个简单的mono脚本, 挂在场景中一个带Renderer的物体上, 通过代码加载并替换原Renderer的材质球. 这里要注意的是, 先加载着色器, 再加载材质球, 通过保证Unity的启动参数为```-force-gles```, 否则材质球会找不到着色器或者因为渲染API不对而报紫.

```c++
public class LoadAb : MonoBehaviour
{
    void Start()
    {
        Renderer renderer = transform.GetComponent<Renderer>();

        AssetBundle shader_ab = AssetBundle.LoadFromFile(Application.streamingAssetsPath + "/shader");
        AssetBundle mat_ab = AssetBundle.LoadFromFile(Application.streamingAssetsPath + "/mat");
        Material[] mats = mat_ab.LoadAllAssets<Material>(); 
        renderer.material = mats[0];
    }


}
```



###### 参考网页

[Unity新版AssetBundle打包API以及使用策略 - 简书 (jianshu.com)

[[实力封装：Unity打包AssetBundle（一）_unity打包package-CSDN博客](https://blog.csdn.net/puss0/article/details/79681013)](https://www.jianshu.com/p/565d02b180ff)

[实力封装：Unity打包AssetBundle（二）-CSDN博客](https://blog.csdn.net/puss0/article/details/79684185)

