using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestMatrix : MonoBehaviour
{
    public Matrix4x4 matrix;    //平移矩阵
    public Vector4 v;           //临时存储矩阵变换之后的点
    public Vector4 startPos;    //物体初始位置
    public Vector4 startScale;  //物体初始缩放
    public Vector4 startRotate; //物体初始旋转
    public Vector3 scale;
    public Vector3 move;
    public Vector3 rotate;

    /// <summary>
    /// 记录初始位置
    /// </summary>
    private void Start()
    {
        startPos = new Vector4(transform.position.x, transform.position.y, transform.position.z, 1);
        startScale = new Vector4(transform.localScale.x, transform.localScale.y, transform.localScale.z, 1);
        startRotate = new Vector4(transform.localRotation.x, transform.localRotation.y, transform.localRotation.z, transform.localRotation.w);
    }

    /// <summary>
    /// Update中平移
    /// </summary>
    private void Update()
    {
        //MyTranslate();
        //MyScale();
        MyRotate();
    }

    /// <summary>
    /// 平移函数
    /// </summary>
    private void MyTranslate()
    {
        matrix = Matrix4x4.identity; //单位矩阵
        matrix.m03 = move.x;
        matrix.m13 = move.y;
        matrix.m23 = move.z;
        v = matrix * startPos;
        transform.position = new Vector3(v.x, v.y, v.z);
    }

    /// <summary>
    /// 缩放函数
    /// </summary>
    private void MyScale()
    {
        matrix = Matrix4x4.identity;
        matrix.m00 = scale.x;
        matrix.m11 = scale.y;
        matrix.m22 = scale.z;
        v = matrix * startScale;
        transform.localScale = new Vector3(v.x, v.y, v.z);
    }

    private void MyRotate()
    {
        //x
        Matrix4x4 matrix_x = Matrix4x4.identity;
        float xr = -Mathf.Deg2Rad * rotate.x;
        matrix_x.m11 = Mathf.Cos(xr);
        matrix_x.m12 = Mathf.Sin(xr);
        matrix_x.m21 = -Mathf.Sin(xr);
        matrix_x.m22 = Mathf.Cos(xr);
        //y
        Matrix4x4  matrix_y = Matrix4x4.identity;
        float yr = -Mathf.Deg2Rad * rotate.y;
        matrix_y.m00 = Mathf.Cos(yr);
        matrix_y.m02 = -Mathf.Sin(yr);
        matrix_y.m20 = Mathf.Sin(yr);
        matrix_y.m22 = Mathf.Cos(yr);
        //z
        Matrix4x4 matrix_z = Matrix4x4.identity;
        float zr = -Mathf.Deg2Rad * rotate.z;
        matrix_z.m00 = Mathf.Cos(zr);
        matrix_z.m01 = Mathf.Sin(zr);
        matrix_z.m10 = -Mathf.Sin(zr);
        matrix_z.m11 = Mathf.Cos(zr);

        transform.localRotation = (matrix_x * matrix_y * matrix_z).rotation;
    }
}
