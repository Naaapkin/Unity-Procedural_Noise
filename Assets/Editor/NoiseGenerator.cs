using System;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

public enum NoiseType
{
    Perlin2D,
    Perlin3D,
    Worley2D,
    Worley3D,
    PerlinWorley2D,
    PerlinWorley3D,
    Simplex2D,
}

public class NoiseGenerator : EditorWindow
{
    private ComputeShader noiseShader;
    private FBMNoise fbmNoise;
    private Texture noise;
    private Editor editor;
    
    private NoiseType noiseType;
    private Vector3Int size;
    private FBMNoise.FBMParameters fbmParameters;
    private bool wrap;

    [MenuItem("Tools/Noise Generator")]
    public static void ShowWindow()
    {
        var window = GetWindow<NoiseGenerator>("Noise Generator");
        window.minSize = new Vector2(320, 500);
    }
    
    private void Awake()
    {
        noiseShader = AssetDatabase.LoadAssetAtPath<ComputeShader>("Assets/Shader/Noise.compute");
        if (noiseShader == null)
        {
            Debug.LogError("Noise shader not found");
            return;
        }
        fbmNoise = new FBMNoise(noiseShader);
        fbmParameters = new()
        {
            seed = Random.Range(-1, Int32.MaxValue) + 1,
            frequency = 1,
            octaves = 6,
            lacunarity = 2,
            persistence = 0.5f
        };

        size = new Vector3Int(256, 256, 256);
        noiseType = NoiseType.Perlin2D;
    }

    private void OnGUI()
    {
        GUIStyle bgColor = new GUIStyle();
        bgColor.normal.background = EditorGUIUtility.whiteTexture;
        if (editor != null) editor.OnInteractivePreviewGUI(GUILayoutUtility.GetRect(256, 256), bgColor);

        noiseType = (NoiseType) EditorGUILayout.EnumPopup("Noise Type", noiseType);
        
        size = Vector3Int.Max(EditorGUILayout.Vector3IntField("Size", size), Vector3Int.one);
        
        FBMParametersGUI();
        switch (noiseType)
        {
            case NoiseType.Perlin2D:
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.Perlin2D((Vector2Int)size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.Perlin3D:
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.Perlin3D(size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.Worley2D:
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.Worley2D((Vector2Int)size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.Worley3D: 
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.Worley3D(size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.PerlinWorley2D:
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.PerlinWorley2D((Vector2Int)size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.PerlinWorley3D:
                wrap = EditorGUILayout.Toggle("Wrap", wrap);
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.PerlinWorley3D(size, fbmParameters, wrap);
                    editor = Editor.CreateEditor(noise);
                }
                break;
            case NoiseType.Simplex2D:
                if (GUILayout.Button("Generate"))
                {
                    noise = fbmNoise.Simplex2D(size, fbmParameters);
                    editor = Editor.CreateEditor(noise);
                }
                break;
        }
        if (GUILayout.Button("Save") && noise != null)
        {
            AssetDatabase.CreateAsset(noise, "Assets/Noise.asset");
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
    
    private void FBMParametersGUI()
    {
        GUILayout.BeginHorizontal();
        fbmParameters.seed = EditorGUILayout.IntField("Seed", fbmParameters.seed);
        if (GUILayout.Button("Random")) fbmParameters.seed = Random.Range(-1, Int32.MaxValue) + 1;
        GUILayout.EndHorizontal();
        
        fbmParameters.frequency = EditorGUILayout.FloatField("Frequency", fbmParameters.frequency);
        fbmParameters.octaves = EditorGUILayout.IntField("Octaves", fbmParameters.octaves);
        fbmParameters.lacunarity = EditorGUILayout.FloatField("Lacunarity", fbmParameters.lacunarity);
        fbmParameters.persistence = EditorGUILayout.FloatField("Persistence", fbmParameters.persistence);
    }
}
