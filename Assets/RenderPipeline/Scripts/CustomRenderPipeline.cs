using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    CommandBuffer commandBuffer = new CommandBuffer() { name = "Render Camera" };

    CullResults cull;

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

    void Render(ScriptableRenderContext context, Camera camera)
    {
        context.SetupCameraProperties(camera);
        CameraClearFlags clearFlags = camera.clearFlags;
        commandBuffer.ClearRenderTarget(
            (clearFlags & CameraClearFlags.Depth) != 0,
            (clearFlags & CameraClearFlags.Color) != 0,
            camera.backgroundColor
        );
        commandBuffer.BeginSample("Render Camera");
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Clear();

        ScriptableCullingParameters cullingParameters;
        if (!CullResults.GetCullingParameters(camera, out cullingParameters))
        {
            return;
        }

        CullResults.Cull(ref cullingParameters, context, ref cull);

        DrawRendererSettings drawSettings = new DrawRendererSettings(camera, new ShaderPassName("SRPDefaultUnlit"));

        FilterRenderersSettings filterSettings = new FilterRenderersSettings(true) {
            renderQueueRange = RenderQueueRange.opaque
        };

        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        drawSettings.sorting.flags = SortFlags.CommonOpaque;

        context.DrawSkybox(camera);

        filterSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        filterSettings.renderQueueRange = RenderQueueRange.transparent;

        DrawDefaultPipeline(context, camera);

        commandBuffer.EndSample("Render Camera");
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Clear();

        context.Submit();
    }

    void DrawDefaultPipeline(ScriptableRenderContext context, Camera camera)
    {
        var drawSettings = new DrawRendererSettings(
            camera, new ShaderPassName("ForwardBase")
        );

        var filterSettings = new FilterRenderersSettings(true);

        context.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );
    }
}
