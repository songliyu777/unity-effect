using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

//原文 https://catlikecoding.com/unity/tutorials/scriptable-render-pipeline/custom-pipeline/

[CreateAssetMenu(menuName = "Rendering/CustomPipeline")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{
    [SerializeField]
    bool dynamicBatching = false;

    [SerializeField]
    bool instancing = false;
    protected override IRenderPipeline InternalCreatePipeline()
    {
        return new CustomRenderPipeline(dynamicBatching, instancing);
    }
}
