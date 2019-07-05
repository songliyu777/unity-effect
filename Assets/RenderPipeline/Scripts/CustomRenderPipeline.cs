using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    CommandBuffer commandBuffer = new CommandBuffer() { name = "Render Camera" };

    CullResults cull;

    DrawRendererFlags drawFlags;

    const int maxVisibleLights = 4;
    //定义光照在shader中使用
    static int visibleLightColorsId = Shader.PropertyToID("_VisibleLightColors");
    static int visibleLightDirectionsOrPositionsId = Shader.PropertyToID("_VisibleLightDirectionsOrPositions");
    static int visibleLightAttenuationsId = Shader.PropertyToID("_VisibleLightAttenuations");

    Vector4[] visibleLightColors = new Vector4[maxVisibleLights];
    Vector4[] visibleLightDirectionsOrPositions = new Vector4[maxVisibleLights];
    Vector4[] visibleLightAttenuations = new Vector4[maxVisibleLights];

    public CustomRenderPipeline(bool dynamicBatching, bool instancing)
    {
        GraphicsSettings.lightsUseLinearIntensity = true;//光照线性空间
        if (dynamicBatching)
        {
            drawFlags = DrawRendererFlags.EnableDynamicBatching;
        }
        if (instancing)
        {
            drawFlags |= DrawRendererFlags.EnableInstancing;
        }

    }
    public override void Dispose()
    {
        base.Dispose();

        if (commandBuffer != null)
        {
            commandBuffer.Dispose();
            commandBuffer = null;
        }
    }

    public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
    {
        base.Render(renderContext, cameras);
        foreach (var camera in cameras)
        {
            Render(renderContext, camera);
        }
    }

    void ConfigureLights()
    {
        if (cull.visibleLights == null)
            return;
        for (int i = 0; i < maxVisibleLights; i++)
        {
            visibleLightColors[i] = Color.clear;
        }
        for (int i = 0; i < cull.visibleLights.Count; i++)
        {
            if (i == maxVisibleLights)
            {
                break;
            }
            VisibleLight light = cull.visibleLights[i];
            visibleLightColors[i] = light.finalColor;
            Vector4 attenuation = Vector4.zero;
            if (light.lightType == LightType.Directional)
            {
                //获取方向，矩阵第3列是Z轴方向
                Vector4 v = light.localToWorld.GetColumn(2);
                v.x = -v.x;
                v.y = -v.y;
                v.z = -v.z;
                visibleLightDirectionsOrPositions[i] = v;
            }
            else
            {
                visibleLightDirectionsOrPositions[i] = light.localToWorld.GetColumn(3);
                //光源的范围衰减
                attenuation.x = 1f / Mathf.Max(light.range * light.range, 0.00001f);
            }
            visibleLightAttenuations[i] = attenuation;
        }
    }

    void Render(ScriptableRenderContext context, Camera camera)
    {
        //渲染上下文
        context.SetupCameraProperties(camera);
        CameraClearFlags clearFlags = camera.clearFlags;
        //清屏
        commandBuffer.ClearRenderTarget(
            (clearFlags & CameraClearFlags.Depth) != 0,
            (clearFlags & CameraClearFlags.Color) != 0,
            camera.backgroundColor
        );
        //配置光源
        ConfigureLights();
        commandBuffer.BeginSample("Render Camera");
        //设置光照数据
        commandBuffer.SetGlobalVectorArray(visibleLightColorsId, visibleLightColors);
        commandBuffer.SetGlobalVectorArray(visibleLightDirectionsOrPositionsId, visibleLightDirectionsOrPositions);
        commandBuffer.SetGlobalVectorArray(visibleLightAttenuationsId, visibleLightAttenuations);
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Clear();

        //剔除
        ScriptableCullingParameters cullingParameters;
        if (!CullResults.GetCullingParameters(camera, out cullingParameters))
        {
            return;
        }

#if UNITY_EDITOR
        if (camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
#endif

        CullResults.Cull(ref cullingParameters, context, ref cull);

        //调用Unity默认的pass unlit pass
        DrawRendererSettings drawSettings = new DrawRendererSettings(camera, new ShaderPassName("SRPDefaultUnlit"));
        drawSettings.flags = drawFlags;
        drawSettings.sorting.flags = SortFlags.CommonOpaque;
        //渲染过滤器
        FilterRenderersSettings filterSettings = new FilterRenderersSettings(true)
        {
            renderQueueRange = RenderQueueRange.opaque
        };

        //渲染不透明物体
        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        //渲染天空盒
        context.DrawSkybox(camera);

        //渲染透明物体
        filterSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        filterSettings.renderQueueRange = RenderQueueRange.transparent;

        DrawDefaultPipeline(context, camera);

        commandBuffer.EndSample("Render Camera");
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Clear();

        context.Submit();
    }

    Material errorMaterial;

    [Conditional("UNITY_EDITOR")]
    void DrawDefaultPipeline(ScriptableRenderContext context, Camera camera)
    {
        if (errorMaterial == null)
        {
            Shader errorShader = Shader.Find("Hidden/InternalErrorShader");
            errorMaterial = new Material(errorShader)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        DrawRendererSettings drawSettings = new DrawRendererSettings(
            camera, new ShaderPassName("ForwardBase")
        );
        drawSettings.flags = drawFlags;

        drawSettings.SetShaderPassName(1, new ShaderPassName("PrepassBase"));
        drawSettings.SetShaderPassName(2, new ShaderPassName("Always"));
        drawSettings.SetShaderPassName(3, new ShaderPassName("Vertex"));
        drawSettings.SetShaderPassName(4, new ShaderPassName("VertexLMRGBM"));
        drawSettings.SetShaderPassName(5, new ShaderPassName("VertexLM"));

        drawSettings.SetOverrideMaterial(errorMaterial, 0);

        var filterSettings = new FilterRenderersSettings(true);

        context.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );
    }
}
