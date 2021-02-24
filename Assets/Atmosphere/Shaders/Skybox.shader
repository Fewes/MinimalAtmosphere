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

Shader "Atmosphere/Skybox"
{
	Properties
	{
		[Toggle] _DrawPlanet ("Draw Planet", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Background" "Queue"="Background" }
		Pass
		{
			ZWrite Off
			Cull Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "Atmosphere.cginc"

			float _DrawPlanet;

			struct appdata_t
			{
				float4 vertex 	: POSITION;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex 		: SV_POSITION;
				float3 worldPos		: TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata_t v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.worldPos	= mul(UNITY_MATRIX_M, v.vertex.xyz);
				o.vertex	= mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.0));

				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				float3 rayStart  = _WorldSpaceCameraPos;
				float3 rayDir    = normalize(i.worldPos - _WorldSpaceCameraPos);
				float  rayLength = INFINITY;

				if (_DrawPlanet == 1.0)
				{
					float2 planetIntersection = PlanetIntersection(rayStart, rayDir);
					if (planetIntersection.x > 0)
						rayLength = min(rayLength, planetIntersection.x);
				}

				float3 lightDir   = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.xyz;

				float3 transmittance;
				float3 color = IntegrateScattering(rayStart, rayDir, rayLength, lightDir, lightColor, transmittance);

				return float4(color, 1);
			}
			ENDCG
		}
	}
}