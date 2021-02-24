// Copyright (c) 2021 Felix Westin
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Shader "Atmosphere/Object"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "Atmosphere.cginc"

			struct v2f
			{
				float4 vertex 	: SV_POSITION;
				float3 normal 	: NORMAL;
				float2 texcoord	: TEXCOORD0;
				float3 worldPos	: TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float4 _Color;

			v2f vert (appdata_full v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.worldPos	= mul(UNITY_MATRIX_M, v.vertex);
				o.vertex	= mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.0));
				o.normal	= mul((float3x3)UNITY_MATRIX_M, v.normal);
				o.texcoord 	= v.texcoord;

				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				float3 rayStart = _WorldSpaceCameraPos;
				float3 rayDir = _WorldSpaceCameraPos - i.worldPos;
				float  rayLength = length(rayDir);
				rayDir /= rayLength;

				float3 lightDir   = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.xyz;

				// Directional light transmittance (planet shadow)
				float3 lightTransmittance = Absorb(IntegrateOpticalDepth(i.worldPos, lightDir));

				// Get a very rough ambient term by sampling the sky straight upwards
				float3 foo;
				float3 ambient = IntegrateScattering(i.worldPos, float3(0, 1, 0), INFINITY, lightDir, lightColor, foo);

				// Combine lighting
				float3 color = _Color * max(0, dot(normalize(i.normal), lightDir)) * (ambient + lightColor * lightTransmittance);

				// Calculate and apply atmospheric scattering + transmittance
				float3 transmittance;
				float3 scattering = IntegrateScattering(rayStart, -rayDir, rayLength, lightDir, lightColor, transmittance);
				color = color * transmittance + scattering;
				
				return float4(color, 1);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}