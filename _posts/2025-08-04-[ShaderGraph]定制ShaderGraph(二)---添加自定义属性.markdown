---
layout: post
title: "定制ShaderGraph(二)---添加自定义属性"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制
math: true


---

# 定制ShaderGraph(二)---添加自定义属性

## 00 前置知识

- 首先, 自定义的属性应该有一个自己的Foldout来折叠起来
- 然后, 自定义的属性应该可以点击后增加输入节点

## 01 实施

### 将自定义属性写到面板上

- 在`UniversalVehiclePaintSubTarget`中添加代码
  ```c#
  sealed class UniversalVehiclePaintSubTarget : UniversalSubTarget
  {
  	...
  	
  	[SerializeField] bool m_BakedGI = false;	// 面板bool值, 为true代表激活输入节点, false则取消激活输入节点
          
      [SerializeField] bool m_ExternalFoldoutOn = false; // Foldout折叠用的bool值
  
  	...
          
      // 对应的属性声明
      public bool bakedGI
      {
          get => m_BakedGI;
          set => m_BakedGI = value;
      }
          
      public bool externalFoldoutOn
      {
          get => m_ExternalFoldoutOn;
          set => m_ExternalFoldoutOn = value;
      }
      
      ...
      
      // ShaderGraph输出框的参数口, 及出现条件
      public override void GetActiveBlocks(ref TargetActiveBlockContext context)
      {
          ...
          // 当面板上的bakedGI为true的时候, 这个属性就出现, 要注意, 此时为false的时候, 只会变灰, 而不会去掉
          // 为了避免污染原来的类, 所以新建了一个ExternalBlockFields的类用来存储自定义的节点
          context.AddBlock(ExternalBlockFields.SurfaceDescription.BakedGI, bakedGI);
      }
      
      ...
          
      // UI绘制
      public override void GetPropertiesGUI(ref TargetPropertyGUIContext context, Action onChange,
          Action<String> registerUndo)
      {
          ...
          // 自定义 External Control 块, 用函数嵌入, 最小的破坏原有结构
          DrawExternalControlGUI(ref context, onChange, registerUndo);
  	}
      
       private void DrawExternalControlGUI(ref TargetPropertyGUIContext context, Action onChange, Action<string> registerUndo)
      {
          // 折叠面板
          var external = new Foldout { value = externalFoldoutOn };
          context.AddFoldout(
              "External Control", 
              external, 
              indentLevel: 0, 	// 缩进定义i
              labelColor: CustomStyles.FoldoutColor,	// 颜色在外部类CustomStyles定义
              callback: evt => {
              externalFoldoutOn = evt.newValue;
              onChange();
          });
  
          // 折叠打开时展示 Baked GI 开关
          if (externalFoldoutOn)
          {
              context.AddProperty(
                  "Baked GI",
                  1,	// 折叠内部的缩进通常要+1
                  new Toggle { value = bakedGI },
                  evt =>
                  {
                      if (bakedGI == evt.newValue) return;
                      registerUndo("Change Baked GI");
                      bakedGI = evt.newValue;
                      onChange();
                  });
          }
      }
      
      // ─── 样式与常量 ─────────────────────────────────
      static class CustomStyles
      {
          public static readonly Color FoldoutColor = new Color(0.3294f, 0.7255f, 0.8196f);
          public const string ExternalFoldoutName = "ExternalControlFoldout";
      }
  }
  
  /// <summary>
  /// 用于声明自定义的ShaderGraph输出的属性节点 <br/>
  /// Unity源文件在com.unity.shadergraph@12.1.10/Editor/Generation/TargetResources/BlockFields.cs
  /// </summary>
  ///
  static class ExternalBlockFields
  {
      /// <summary>
      /// 自定义的表面参数
      /// </summary>
      [GenerateBlocks("External")]	// "External"为在ShaderGraph里面手动添加时的菜单路径
      public struct SurfaceDescription
      {
          public static string name = "SurfaceDescription";
          // 此时的ColorControl是为了确定默认初始值, 后面的True表示是HDR颜色
          public static BlockFieldDescriptor BakedGI = new(name, "BakedGI", "Baked GI",
              "SURFACEDESCRIPTION_BAKEDGI", new ColorControl(new Color(1,1,1,0),true), ShaderStage.Fragment); 
      }
  }
  ```

  

- 如果要让自定义的字段能够自动"出现"和"去掉", 那么就需要在`LitBlockMasks`类中添加`BlockFieldDescriptor[]`, 当然, 我们为了最小侵入, 新建一个类`ExternalBlockMasks`, 然后声明一个`BlockFieldDescriptor[]`, 将`ExternalBlockFields.SurfaceDescription.BakedGI`加入. 同时, 要在构建的`SubShader`的时候, 调用这个Block, 此时, 才可以触发重排, 也就是视觉上的"出现"和"去掉".
  ```c#
  static class LitBlockMasks
  {
  	...
  }
  
   static class ExternalBlockMasks
   {
       ...
       public static readonly BlockFieldDescriptor[] FragmentVehiclePaint = new BlockFieldDescriptor[]
      {
          BlockFields.SurfaceDescription.BaseColor,
          BlockFields.SurfaceDescription.NormalOS,
          BlockFields.SurfaceDescription.NormalTS,
          BlockFields.SurfaceDescription.NormalWS,
          BlockFields.SurfaceDescription.Emission,
          BlockFields.SurfaceDescription.Metallic,
          BlockFields.SurfaceDescription.Specular,
          BlockFields.SurfaceDescription.Smoothness,
          BlockFields.SurfaceDescription.Occlusion,
          BlockFields.SurfaceDescription.Alpha,
          BlockFields.SurfaceDescription.AlphaClipThreshold,
          BlockFields.SurfaceDescription.CoatMask,
          BlockFields.SurfaceDescription.CoatSmoothness,
  
          #region CustomAddCode
  
          ExternalBlockFields.SurfaceDescription.BakedGI
  
          #endregion
      };
   }
  
  // 在创建SubShader的时候, 将ExternalBlockMasks.FragmentVehiclePaint作为参数传入
  public static SubShaderDescriptor LitGLESSubShader(UniversalTarget target, WorkflowMode workflowMode,
              string renderType, string renderQueue, bool complexLit)
  {
      ...
      if (complexLit)
          result.passes.Add(ExternalPasses.ForwardOnly(target, workflowMode, complexLit, CoreBlockMasks.Vertex,
              // CustomAddCode
              // ExternalBlockMasks.FragmentComplexLit, CorePragmas.Forward));
              ExternalBlockMasks.FragmentVehiclePaint, CorePragmas.Forward));
  	else
      	result.passes.Add(ExternalPasses.Forward(target, workflowMode));
  }
  ```

- 至此, 我们完成了面板和输入节点的自定义
  ![image-20250804164306677](/assets/image/image-20250804164306677.png)

### 应用自定义属性到最终着色器中

- 探寻是如何生成代码的

  - Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Importers/ShaderGraphImporterEditor.cs
    - 文件中
      ![image-20250804175706409](/assets/image/image-20250804175706409.png)

- Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Processors/Generator.cs

  - 文件中有个`BuildShader()`函数, 貌似就是总调用了
    ```c#
    void BuildShader()
    {
        var activeNodeList = Pool.ListPool<AbstractMaterialNode>.Get();
        bool ignoreActiveState = (m_Mode == GenerationMode.Preview);  // for previews, we ignore node active state
        if (m_OutputNode == null)
        {
            foreach (var block in m_ActiveBlocks)
            {
                // IsActive is equal to if any active implementation has set active blocks
                // This avoids another call to SetActiveBlocks on each TargetImplementation
                if (!block.isActive)
                    continue;
    
                NodeUtils.DepthFirstCollectNodesFromNode(activeNodeList, block, NodeUtils.IncludeSelf.Include, ignoreActiveState: ignoreActiveState);
            }
        }
        else
        {
            NodeUtils.DepthFirstCollectNodesFromNode(activeNodeList, m_OutputNode, ignoreActiveState: ignoreActiveState);
        }
    
        var shaderProperties = new PropertyCollector();
        var shaderKeywords = new KeywordCollector();
        m_GraphData.CollectShaderProperties(shaderProperties, m_Mode);
        m_GraphData.CollectShaderKeywords(shaderKeywords, m_Mode);
    
        var graphInputOrderData = new List<GraphInputData>();
        foreach (var cat in m_GraphData.categories)
        {
            foreach (var input in cat.Children)
            {
                graphInputOrderData.Add(new GraphInputData()
                {
                    isKeyword = input is ShaderKeyword,
                    referenceName = input.referenceName
                });
            }
        }
        string path = AssetDatabase.GUIDToAssetPath(m_GraphData.assetGuid);
    
        // Send an action about our current variant usage. This will either add or clear a warning if it exists
        var action = new ShaderVariantLimitAction(shaderKeywords.permutations.Count, ShaderGraphPreferences.variantLimit);
        m_GraphData.owner?.graphDataStore?.Dispatch(action);
    
        if (shaderKeywords.permutations.Count > ShaderGraphPreferences.variantLimit)
        {
            string graphName = "";
            if (m_GraphData.owner != null)
            {
                if (path != null)
                {
                    graphName = Path.GetFileNameWithoutExtension(path);
                }
            }
            Debug.LogError($"Error in Shader Graph {graphName}:{ShaderKeyword.kVariantLimitWarning}");
    
            m_ConfiguredTextures = shaderProperties.GetConfiguredTextures();
            m_Builder.AppendLines(ShaderGraphImporter.k_ErrorShader.Replace("Hidden/GraphErrorShader2", graphName));
            // Don't continue building the shader, we've already built an error shader.
            return;
        }
    
        foreach (var activeNode in activeNodeList.OfType<AbstractMaterialNode>())
        {
            activeNode.SetUsedByGenerator();
            activeNode.CollectShaderProperties(shaderProperties, m_Mode);
        }
    
        // Collect excess shader properties from the TargetImplementation
        foreach (var target in m_Targets)
        {
            // TODO: Setup is required to ensure all Targets are initialized
            // TODO: Find a way to only require this once
            TargetSetupContext context = new TargetSetupContext();
            target.Setup(ref context);
    
            target.CollectShaderProperties(shaderProperties, m_Mode);
        }
    
        // set the property collector to read only
        // (to ensure no rogue target or pass starts adding more properties later..)
        shaderProperties.SetReadOnly();
    
        m_Builder.AppendLine(@"Shader ""{0}""", m_Name);
        using (m_Builder.BlockScope())
        {
            GenerationUtils.GeneratePropertiesBlock(m_Builder, shaderProperties, shaderKeywords, m_Mode, graphInputOrderData);
            for (int i = 0; i < m_Targets.Length; i++)
            {
                TargetSetupContext context = new TargetSetupContext(m_assetCollection);
    
                // Instead of setup target, we can also just do get context
                m_Targets[i].Setup(ref context);
    
                var subShaderProperties = GetSubShaderPropertiesForTarget(m_Targets[i], m_GraphData, m_Mode, m_OutputNode, m_TemporaryBlocks);
                foreach (var subShader in context.subShaders)
                {
                    GenerateSubShader(i, subShader, subShaderProperties);
                }
    
                var customEditor = context.defaultShaderGUI;
                if (customEditor != null && m_Targets[i].WorksWithSRP(GraphicsSettings.currentRenderPipeline))
                {
                    m_Builder.AppendLine("CustomEditor \"" + customEditor + "\"");
                }
    
                foreach (var rpCustomEditor in context.customEditorForRenderPipelines)
                {
                    m_Builder.AppendLine($"CustomEditorForRenderPipeline \"{rpCustomEditor.shaderGUI}\" \"{rpCustomEditor.renderPipelineAssetType}\"");
                }
    
                m_Builder.AppendLine("CustomEditor \"" + typeof(GenericShaderGraphMaterialGUI).FullName + "\"");
            }
    
            m_Builder.AppendLine(@"FallBack ""Hidden/Shader Graph/FallbackError""");
        }
    
        m_ConfiguredTextures = shaderProperties.GetConfiguredTextures();
    }
    ```

  - 其中的关键数据结构是`GraphData : JsonObject`

    - 路径是`Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Data/Graphs/GraphData.cs`
    - 值得注意的是, 这是个`partial class`, 由五个部分组成
      <img src="/assets/image/image-20250804180559252.png" alt="image-20250804180559252" style="zoom:50%;" />

  - 由于我们不关心节点部分的代码, 实际上模板部分的代码是
    ```c#
     // Process Template
    Profiler.BeginSample("ProcessTemplate");
    var templatePreprocessor = new ShaderSpliceUtil.TemplatePreprocessor(activeFields, spliceCommands,
        isDebug, sharedTemplateDirectories, m_assetCollection, m_humanReadable);
    templatePreprocessor.ProcessTemplateFile(passTemplatePath);
    m_Builder.Concat(templatePreprocessor.GetShaderCode());
    
    Profiler.EndSample();
    ```

- Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Processors/ShaderSpliceUtil.cs

  - 通过`templatePreprocessor.GetShaderCode()`这个方法, 我们找到了`ShaderSpliceUtil.cs`
    ```c#
    public ShaderStringBuilder GetShaderCode()
    {
        return result;
    }
    ```

    

  - 其中result
    ```c#
    public TemplatePreprocessor(ActiveFields activeFields, Dictionary<string, string> namedFragments, bool isDebug, string[] templatePaths, AssetCollection assetCollection, bool humanReadable, ShaderStringBuilder outShaderCodeResult = null)
    {
        this.activeFields = activeFields;
        this.namedFragments = namedFragments;
        this.isDebug = isDebug;
        this.templatePaths = templatePaths;
        this.assetCollection = assetCollection;
        this.result = outShaderCodeResult ?? new ShaderStringBuilder(humanReadable: humanReadable);
        includedFiles = new HashSet<string>();
    }
    ```

  - `ShaderStringBuilder`这个类看起来就很像我们要找的目标了
    路径: `Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Processors/ShaderStringBuilder.cs`
  
    ```c#
    public ShaderStringBuilder(int indentationLevel = 0, int stringBuilderSize = 8192, bool humanReadable = false)
    {
        IncreaseIndent(indentationLevel);
        m_StringBuilder = new StringBuilder(stringBuilderSize);
        m_ScopeStack = new Stack<ScopeType>();
        m_Mappings = new List<ShaderStringMapping>();
        m_CurrentMapping = new ShaderStringMapping();
        m_HumanReadable = humanReadable;
    }
    ```
  
  - 回到Generator.cs
    ```c#
    // Render State
    Profiler.BeginSample("RenderState");
    using (var renderStateBuilder = new ShaderStringBuilder(humanReadable: m_humanReadable))
    {
        // Render states need to be separated by RenderState.Type
        // The first passing ConditionalRenderState of each type is inserted
        foreach (RenderStateType type in Enum.GetValues(typeof(RenderStateType)))
        {
            var renderStates = pass.renderStates?.Where(x => x.descriptor.type == type);
            if (renderStates != null)
            {
                foreach (RenderStateCollection.Item renderState in renderStates)
                {
                    if (renderState.TestActive(activeFields))
                    {
                        // 这一行应该就是把代码加入
                        renderStateBuilder.AppendLine(renderState.value);
    
                        // Cull is the only render state type that causes a compilation error
                        // when there are multiple Cull directive with different values in a pass.
                        if (type == RenderStateType.Cull)
                            break;
                    }
                }
            }
        }
    
        // 这一行是把对应的部分换成加入后的代码
        string command = GenerationUtils.GetSpliceCommand(renderStateBuilder.ToCodeBlock(), "RenderState");
        // 这一行应该是应用
        spliceCommands.Add("RenderState", command);
    }
    Profiler.EndSample();
    ```
  
    要替换的模板路径是: `Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Templates/ShaderPass.template`
  
    ```c#
    // 这三个函数应该就是生成SubShader
    
    // 此函数被BuildShader调用, 又调用了GenerateShaderPass
    void GenerateSubShader(int targetIndex, SubShaderDescriptor descriptor, PropertyCollector subShaderProperties)
    
    // 此函数被BuildShader调用
    static PropertyCollector GetSubShaderPropertiesForTarget(Target target, GraphData graph, GenerationMode generationMode, AbstractMaterialNode outputNode, List<BlockNode> outTemporaryBlockNodes)
    
    void GenerateShaderPass(int targetIndex, PassDescriptor pass, ActiveFields activeFields, List<BlockFieldDescriptor> currentBlockDescriptors, PropertyCollector subShaderProperties)
    ```
  
    - GenerateSubShaderTags()函数用来生成SubShader的Tags
      路径: `Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Processors/GenerationUtils.cs`
  
      ```c#
      internal static void GenerateSubShaderTags(Target target, SubShaderDescriptor descriptor, ShaderStringBuilder builder)
      ```
  
  - 关于`PackedVarings`的来历
  
    - 首先, 在`Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Processors/GenerationUtils.cs`中
      ```c#
      internal static void GeneratePackedStruct(StructDescriptor shaderStruct, ActiveFields activeFields, out StructDescriptor packStruct)
      {
          packStruct = new StructDescriptor()
          {
              // 这里提到了将"Packed"与"shaderStruct.name", 结合起来作为Struct的名字
              name = "Packed" + shaderStruct.name,
              packFields = true,
              fields = new FieldDescriptor[] { }
          };
          List<FieldDescriptor> packedSubscripts = new List<FieldDescriptor>();
          List<FieldDescriptor> postUnpackedSubscripts = new List<FieldDescriptor>();
          List<int> packedCounts = new List<int>();
          foreach (FieldDescriptor subscript in shaderStruct.fields)
          {
              var fieldIsActive = false;
              var keywordIfDefs = string.Empty;
      
              if (activeFields.permutationCount > 0)
              {
                  //find all active fields per permutation
                  var instances = activeFields.allPermutations.instances
                      .Where(i => IsFieldActive(subscript, i, subscript.subscriptOptions.HasFlag(StructFieldOptions.Optional))).ToList();
                  fieldIsActive = instances.Count > 0;
                  if (fieldIsActive)
                      keywordIfDefs = KeywordUtil.GetKeywordPermutationSetConditional(instances.Select(i => i.permutationIndex).ToList());
              }
              else
                  fieldIsActive = IsFieldActive(subscript, activeFields.baseInstance, subscript.subscriptOptions.HasFlag(StructFieldOptions.Optional));
              //else just find active fields
      
              if (fieldIsActive)
              {
                  // special case, "UNITY_STEREO_INSTANCING_ENABLED" fields must be packed at the end of the struct because they are system generated semantics
                  //
                  if (subscript.HasPreprocessor() && (subscript.preprocessor.Contains("INSTANCING")))
                      postUnpackedSubscripts.Add(subscript);
                  // special case, "SHADER_STAGE_FRAGMENT" fields must be packed at the end of the struct,
                  // otherwise the vertex output struct will have different semantic ordering than the fragment input struct.
                  //
                  else if (subscript.HasPreprocessor() && (subscript.preprocessor.Contains("SHADER_STAGE_FRAGMENT")))
                      postUnpackedSubscripts.Add(subscript);
                  else if (subscript.HasSemantic() || subscript.vectorCount == 0)
                      packedSubscripts.Add(subscript);
                  else
                  {
                      // pack float field
                      int vectorCount = subscript.vectorCount;
                      // super simple packing: use the first interpolator that has room for the whole value
                      int interpIndex = packedCounts.FindIndex(x => (x + vectorCount <= 4));
                      int firstChannel;
                      if (interpIndex < 0 || subscript.HasPreprocessor())
                      {
                          // allocate a new interpolator
                          interpIndex = packedCounts.Count;
                          firstChannel = 0;
                          packedCounts.Add(vectorCount);
                      }
                      else
                      {
                          // pack into existing interpolator
                          firstChannel = packedCounts[interpIndex];
                          packedCounts[interpIndex] += vectorCount;
                      }
                  }
              }
          }
          for (int i = 0; i < packedCounts.Count(); ++i)
          {
              // todo: ensure this packing adjustment doesn't waste interpolators when many preprocessors are in use.
              var packedSubscript = new FieldDescriptor(packStruct.name, "interp" + i, "", "float" + packedCounts[i], "INTERP" + i, "", StructFieldOptions.Static);
              packedSubscripts.Add(packedSubscript);
          }
          packStruct.fields = packedSubscripts.Concat(postUnpackedSubscripts).ToArray();
      }
      ```
  
    - 然后, 在`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/UniversalStructs.cs`中又有, 其中`name`为`Varings`, 所以, 合在一起就是`PackedVarings`
      ```c#
      static class UniversalStructs
      {
          public static StructDescriptor Varyings = new StructDescriptor()
          {
              name = "Varyings",
              packFields = true,
              populateWithCustomInterpolators = true,
              fields = new FieldDescriptor[]
              {
                  StructFields.Varyings.positionCS,
                  StructFields.Varyings.positionWS,
                  StructFields.Varyings.normalWS,
                  StructFields.Varyings.tangentWS,
                  StructFields.Varyings.texCoord0,
                  StructFields.Varyings.texCoord1,
                  StructFields.Varyings.texCoord2,
                  StructFields.Varyings.texCoord3,
                  StructFields.Varyings.color,
                  StructFields.Varyings.viewDirectionWS,
                  StructFields.Varyings.screenPosition,
                  UniversalStructFields.Varyings.staticLightmapUV,
                  UniversalStructFields.Varyings.dynamicLightmapUV,
                  UniversalStructFields.Varyings.sh,
                  UniversalStructFields.Varyings.fogFactorAndVertexLight,
                  UniversalStructFields.Varyings.shadowCoord,
                  StructFields.Varyings.instanceID,
                  UniversalStructFields.Varyings.stereoTargetEyeIndexAsBlendIdx0,
                  UniversalStructFields.Varyings.stereoTargetEyeIndexAsRTArrayIdx,
                  StructFields.Varyings.cullFace,
              }
          };
      }
      ```
  
  - Pass的模板在`Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Templates/PassMesh.template`
  
  - 生成代码时, 大概是`input.shaderOutputName`
    ```c#
    static void GenerateSurfaceDescriptionRemap(
                GraphData graph,
                AbstractMaterialNode rootNode,
                IEnumerable<MaterialSlot> slots,
                ShaderStringBuilder surfaceDescriptionFunction,
                GenerationMode mode)
    {
        if (rootNode == null)
        {
            foreach (var input in slots)
            {
                if (input != null)
                {
                    var node = input.owner;
                    var foundEdges = graph.GetEdges(input.slotReference).ToArray();
                    // 这里的shaderOutputName
                    var hlslName = NodeUtils.GetHLSLSafeName(input.shaderOutputName);
                    if (foundEdges.Any())
                        surfaceDescriptionFunction.AppendLine($"surface.{hlslName} = {node.GetSlotValue(input.id, mode, node.concretePrecision)};");
                    else
                        surfaceDescriptionFunction.AppendLine($"surface.{hlslName} = {input.GetDefaultValue(mode, node.concretePrecision)};");
                }
            }
        }
    ```
  
  - 对应的是声明面板时的第二个参, 即"BakedGI"
    ```c#
    /// <summary>
    /// 用于声明自定义的ShaderGraph输出的属性节点 <br/>
    /// Unity源文件在com.unity.shadergraph@12.1.10/Editor/Generation/TargetResources/BlockFields.cs
    /// </summary>
    ///
    static class ExternalBlockFields
    {
        /// <summary>
        /// 自定义的表面参数
        /// </summary>
        [GenerateBlocks("External")]	// "External"为在ShaderGraph里面手动添加时的菜单路径
        public struct SurfaceDescription
        {
            public static string name = "SurfaceDescription";
            // 此时的ColorControl是为了确定默认初始值, 后面的True表示是HDR颜色, 第二个参是hlsl中使用的名称, 与name
            // 合并起来就是通过SurfaceDescription.BakedGI来调用
            public static BlockFieldDescriptor BakedGI = new(name, "BakedGI", "Baked GI",
                "SURFACEDESCRIPTION_BAKEDGI", new ColorControl(new Color(1,1,1,0),true), ShaderStage.Fragment); 
        }
    }
    ```
  
    

###### 参考网页

- [ShaderGraph自定义Master Node解析-URP(LWRP) - 知乎](https://zhuanlan.zhihu.com/p/85402257)
