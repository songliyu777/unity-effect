using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InstancedColor : MonoBehaviour
{
    [SerializeField]
    Color color = Color.white;
    static int colorID = Shader.PropertyToID("_Color");
    void Awake()
    {
        OnValidate();
    }

    void OnValidate()
    {
        var propertyBlock = new MaterialPropertyBlock();
        propertyBlock.SetColor(colorID, color);
        GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);
    }
}
