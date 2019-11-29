// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TimeStop" {
	Properties{
		_NoiseMap("Noise Map", 2D) = "white" {}
		// 각 충돌 위치와 시간에 따른 distortion할 거리값
		_HitPoint0("Hit Point & Distance", Vector) = (0.0, 0.0, 0.0, -1.0)
		_HitPoint1("Hit Point & Distance", Vector) = (0.0, 0.0, 0.0, -1.0)
		_HitPoint2("Hit Point & Distance", Vector) = (0.0, 0.0, 0.0, -1.0)
		_DistortionWeight("Distortion Weight", float) = 50
		_RimColor("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader{
		Tags { "Queue" = "Transparent+1" "RenderType" = "Opaque" }

		GrabPass { }

		Pass {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f {
				float4 uvgrab : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldpos : TEXCOORD3;
				float2 uvmain : TEXCOORD4;
				float4 vertex : SV_POSITION;
			};

			float4 _NoiseMap_ST;

			v2f vert(appdata_full v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldpos = mul(unity_ObjectToWorld, v.vertex);
				o.uvmain = TRANSFORM_TEX(v.texcoord, _NoiseMap);

			#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
			#else
				float scale = 1.0;
			#endif
				o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w)*0.5;
				o.uvgrab.zw = o.vertex.zw;
				o.normal = mul((float3x3)unity_ObjectToWorld, v.normal);
				return o;
			}

			sampler2D	_GrabTexture;
			sampler2D	_MainTex;
			float4		_HitPoint0;
			float4		_HitPoint1;
			float4		_HitPoint2;
			float		_DistortionWeight;
			float4		_GrabTexture_TexelSize;
			float4		_RimColor;
			sampler2D	_NoiseMap;

			float GetDistortionScale(float3 pos, float4 hitPoint) {
				float distortion = 0.0f;
				// 해당 픽셀과 초기 충돌 위치와의 거리
				float dis = distance(hitPoint.xyz, pos);
				// distortion되는 영역의 크기                            
				float hitSize = 2.0f;
				// 해당 픽셀이 영역에 들어왔는지 확인하고 중앙에서부터 멀어 질수록 희미하게 만든다.
				distortion = (hitPoint.w - dis) / (hitSize / 2.0f);
				distortion = max(0.0f, -(distortion*distortion) + 1.0f);
				// 충돌점으로 부터 멀어지면 약해지게 되고 일정 거리를 넘어가면 사라진다.
				float maxDistance = 6.0f;
				distortion *= max(0.0f, (-dis * dis / maxDistance / maxDistance + 1.0f));
				return distortion;
			}

			float4 frag(v2f i) : SV_Target {
				// 최대 3가지의 물체에 대해 distortion을 처리한다.
				float distortion = GetDistortionScale(i.worldpos, _HitPoint0);
				distortion += GetDistortionScale(i.worldpos, _HitPoint1);
				distortion += GetDistortionScale(i.worldpos, _HitPoint2);
				// noise map의 값을 가져온다.
				half2 bump = UnpackNormal(tex2D(_NoiseMap, i.uvmain)).xy;
				// 해당 랜덤한 값에 distortion정도값, 현재렌더 타겟의 사이즈, 값만큼을 곱해 offset을 구한다.
				float2 offset = bump * _DistortionWeight * _GrabTexture_TexelSize.xy * distortion;
				// 해당 offset만큼 이동한곳의 픽셀값을 가져온다.
				i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
				float4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
				// 태두리의 색을 위해 림라이트 계산을 한다.
				i.normal = normalize(i.normal);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz – i.worldpos);
				float3 rimColor = pow(1 - saturate(dot(viewDirection, i.normal)), 10.0f) * 2.0f * _RimColor.rgb;
				col.rgb += rimColor;
				return col;
			}
			ENDCG
		}
	}
}
