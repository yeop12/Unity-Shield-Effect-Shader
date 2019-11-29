# Unity-Shield-Effect-Shader
프로젝트 Horizon에서 일정 영역에 시간이 멈추는 효과를 구현하였습니다.


## 참고 이펙트
인터넷을 돌아다니다가 원하던 형태의 이펙트를 발견하여 참고하였습니다.


| ![UDK_Shield_Effect](https://user-images.githubusercontent.com/11326612/69848410-67558c00-12bd-11ea-973d-6a7bcf67c27c.gif) |
|:--:| 
| *[출처]: https://youtu.be/VozAvdeY8eA* |


## 이펙트 구현
위의 동영상에는 따로 코드가 없어 이미지를 보고 추측하여 구현하였습니다.
구현에는 아래 4가지 요소를 포함하고 싶었습니다.
- 구형 바깥 부분이 빛날 것
- 충돌 위치로부터 distortion층이 퍼져 나갈 것
- distortion층은 중앙이 가장 distortion되고 끝 부분으로 갈수록 줄어들 것
- 충돌 위치로부터 어느정도 퍼지고 나면 사라질 것


| ![TimeStopEffect](https://user-images.githubusercontent.com/11326612/69849664-b650f080-12c0-11ea-8956-21d7cffa1b50.gif) |
|:--:| 
| *구현한 이펙트* |


## 구현 방법
- 구형 바깥 부분이 빛날 것


  → 림 쉐이더로 구현하였습니다.
  
  
아래 3가지 사항은 픽셀 쉐이더에서 각각의 픽셀 값을 정할 때 distortion scale을 얼마나 줄 것인지에 대한 함수를 제작하여 구현하였습니다.  
```
// pos : 픽셀 위치, hitPoint : (x,y,z=충돌 위치, w=distortion범위 확산 거리)
float GetDistortionScale(float3 pos, float4 hitPoint)
```  
- 충돌 위치로부터 distortion층이 퍼져 나갈 것
- distortion층은 중앙이 가장 distortion되고 끝 부분으로 갈수록 줄어들 것  
``` 
float distortion = 0.0f;
// 해당 픽셀과 초기 충돌 위치와의 거리
float dis = distance(hitPoint.xyz, pos);
// distortion되는 영역의 크기                            
float hitSize = 2.0f;
// 해당 픽셀이 영역에 들어왔는지 확인하고 중앙에서부터 멀어 질수록 희미하게만든다.
distortion = (hitPoint.w - dis) / (hitSize / 2.0f);
distortion = max(0.0f, -(distortion*distortion) + 1.0f);
``` 

