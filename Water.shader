Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _DepthShallow("Depth Color Shallow", Color) = (1,1,1,1)
        _DepthDeep("Depth Color Deep", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Direction("Wave Direction 2D", Vector) = (1,0,0,0)
        _Speed("Wave Speed", Float) = 0.5
        _Amplitude("Wave Amplitude", Float) = 0.5
        _Wavelength("Wave Frequency", Float) = 10
        _SpeedW2("Under Wave Speed", Float) = 0.5
        _AmplitudeW2("Under Wave Amplitude", Float) = 0.5
        _WavelengthW2("Under Wave Frequency", Float) = 5
        _DepthCutoff("Depth Saturation Length", Float) = 10
        _Foam ("Foam Thickness", Range(0,3)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "DisableBatching" = "True" "Queue" = "Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _CameraDepthTexture;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color, _DepthShallow, _DepthDeep, _FoamColor;
        float _Speed, _Amplitude, _Wavelength, _SpeedW2, _AmplitudeW2, _WavelengthW2, _DepthCutoff, _Foam;
        float2 _Direction;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float4 screenPos;
        };

        void vert(inout appdata_full v)
        {
            float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
            float3 posV = v.vertex;
            float2 dir = float2(normalize(_Direction.x - worldPos.x), normalize(_Direction.y - worldPos.z));
            float fUnderW = _AmplitudeW2 * sin(_Time.y * _SpeedW2 + (dir.x * worldPos.x  + dir.y * worldPos.z) * _WavelengthW2);
            float fWave = _Amplitude * sin(_Time.y * _Speed + (worldPos.x * worldPos.z) * _Wavelength);
            posV.y = fUnderW;
            posV.y += fWave;

            float3 tan = float3(1, cos(_Time.y * _SpeedW2 + (dir.x * worldPos.x + dir.y * worldPos.z) * _WavelengthW2) + cos(_Time.y * _Speed + (worldPos.x * worldPos.z) * _Wavelength), 0);
            float3 newNormal = float3(-tan.y, tan.x, 0);

            v.normal = normalize(newNormal);
            v.vertex.xyz = posV;
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)).r);
            float depthDif = depth - IN.screenPos.w;
            fixed4 c = lerp(_DepthShallow, _DepthDeep, saturate(depthDif/_DepthCutoff));
            half4 foam = 1 - saturate(_Foam * (depth - IN.screenPos.w));
            c += foam * _FoamColor;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
