using Unity.Collections;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class Utility
{
#if UNITY_EDITOR
    // 添加到 Camera 的右键上下文菜单
    [MenuItem("CONTEXT/Camera/Create Screenshot")]
    private static void CreateScreenShot(MenuCommand command)
    {
        Camera camera = command.context as Camera;
        if (camera == null)
        {
            Debug.LogError("No Camera found!");
            return;
        }
        ScreenCapture.CaptureScreenshot(Application.dataPath + "/Screenshot.png");
    }
#endif
    
    public static RenderTexture CreateRenderTexture(int width, int height, int depth, RenderTextureFormat format, TextureDimension d)
    {
        RenderTexture rt = new RenderTexture(width, height, 0,
            format, RenderTextureReadWrite.Linear)
        {
            volumeDepth = depth,
            dimension = d,
            useMipMap = false,
            autoGenerateMips = false,
            anisoLevel = 6,
            filterMode = FilterMode.Trilinear,
            wrapMode = TextureWrapMode.Repeat,
            enableRandomWrite = true
        };
        rt.Create();
        return rt;
    }
    
    public static void ReadRT3D<T>(RenderTexture rt, Texture3D tex) where T : struct
    {
        var a = new NativeArray<T>(rt.width * rt.height * rt.volumeDepth, Allocator.Persistent, NativeArrayOptions.UninitializedMemory);
        AsyncGPUReadback.RequestIntoNativeArray(ref a, rt, 0, _ =>
        {
            tex.SetPixelData(a, 0);
            tex.Apply(updateMipmaps: false, makeNoLongerReadable: true);
            a.Dispose();
        });
    }
    
    public static void ReadRT2D(RenderTexture rt, Texture2D tex)
    {
        AsyncGPUReadback.Request(rt, 0, data =>
        {
            tex.SetPixelData(data.GetData<byte>(), 0);
            tex.Apply(updateMipmaps: false, makeNoLongerReadable: true);
            rt.Release();
        });
    }
}