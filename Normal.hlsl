//───────────────────────────────────────
 // テクスチャ＆サンプラーデータのグローバル変数定義
//───────────────────────────────────────
Texture2D		g_texture : register(t0);	//テクスチャー
SamplerState	g_sampler : register(s0);	//サンプラー
Texture2D		normalTex : register(t1);

//───────────────────────────────────────
// コンスタントバッファ
// DirectX 側から送信されてくる、ポリゴン頂点以外の諸情報の定義
//───────────────────────────────────────
cbuffer gmodel:register(b0)
{
	float4x4	matWVP;			// ワールド・ビュー・プロジェクションの合成行列
	float4x4	matW;           // ワールド行列
	float4x4	matNormal;           //ノーマルのローカルへの変換行列から平行移動成分をとったやつ
	float4		diffuseColor;		//マテリアルの色＝拡散反射係数
	float4		ambientColor;		//環境光
	float4		specularColor;		//鏡面反射＝ハイライトの係数
	float		shininess;			//ハイライトの広がりの大きさ
	int		isTextured;			//テクスチャーが貼られているかどうか
	int		isNormalMap;		//ノーマルマップがあるかどうか
	float	scrollx;
	float	scrolly;
};

cbuffer gmodel:register(b1)
{
	float4		lightPosition;		//光源の位置（平行光源の時は、その位置から原点へのベクトル
	float4		eyePosition;		//視点位置＝カメラ位置
};


//───────────────────────────────────────
// 頂点シェーダー出力＆ピクセルシェーダー入力データ構造体
//───────────────────────────────────────
struct VS_OUT
{
	float4 pos  : SV_POSITION;	//ピクセル位置
	float2 uv	: TEXCOORD;		//UV座標
	float4 eyev		:POSITION;	//ワールド座標に変換された視線ベクトル
	float4 Neyev	:POSITION1; //ノーマルマップ用の接空間に変換された視線ベクトル
	float4 normal	:POSITION2;	//法線ベクトル
	float4 light	:POSITION3; //ライトを接空間に変換したベクトル
	float4 color	:POSITION4; //通常のランバートモデルの拡散反射の色
};

//───────────────────────────────────────
// 頂点シェーダ
//───────────────────────────────────────
VS_OUT VS(float4 pos : POSITION, float4 uv : TEXCOORD, float4 normal : NORMAL, float4 tangent : TANGENT)
{
	//ピクセルシェーダーへ渡す情報
	VS_OUT outData = (VS_OUT)0;

	//ローカル座標に、ワールド・ビュー・プロジェクション行列をかけて
	//スクリーン座標に変換し、ピクセルシェーダーへ
	outData.pos = mul(pos, matWVP);
	outData.uv = (float2)uv;

	float3  binormal = cross(normal, tangent);

	
	normal = mul(normal, matNormal);
	normal = normalize(normal); //法線ベクトルをローカル座標に変換したやつ
	normal.w = 0;
	outData.normal = normal;

	tangent.w = 0;
	tangent = mul(tangent, matNormal);
	tangent = normalize(tangent); //接線ベクトルをローカル座標に変換したやつ

	binormal = mul(binormal, matNormal);
	binormal = normalize(binormal); //従法線ベクトルをローカル座標に変換したやつ

	float4 posw = mul(pos, matW);
	float4 eye = normalize(mul(pos, matW) - eyePosition);
	outData.eyev = eye;

	outData.Neyev.x = dot(eye, tangent);//接空間の視線ベクトル
	outData.Neyev.y = dot(eye, binormal);
	outData.Neyev.z = dot(eye, outData.normal);
	outData.Neyev.w = 0;

	float4 light = normalize(lightPosition);
	light.w = 0;
	light = normalize(light);



	outData.color = mul(light, outData.normal);
	outData.color.w = 0.0;

	
	outData.light.x = dot(light, tangent);//接空間の光源ベクトル
	outData.light.y = dot(light, binormal);
	outData.light.z = dot(light, outData.normal);
	outData.light.w = 0;

	//まとめて出力
	return outData;
}

//───────────────────────────────────────
// ピクセルシェーダ
//───────────────────────────────────────
float4 PS(VS_OUT inData) : SV_Target
{
	float4 lightSource = float4(1.0, 1.0, 1.0, 1.0);
	float4 diffuse;
	float4 ambient;

	float2 tmpUV = inData.uv;
	tmpUV.x = tmpUV.x + scrollx;
	tmpUV.y = tmpUV.y - scrolly;
	// ノーマルマップテクスチャの有無の確認
	//if (hasNormalTexture)return float4(1, 0, 0, 1);
	//return float4(0, 0, 0, 1);


	/*if (hasNormalTexture)
		return g_normal_texture.Sample(g_sampler, inData.uv);
	else*/

	if (isNormalMap)
	{
		//inData.light = normalize(inData.light);
		float4 tmpNormal = normalTex.Sample(g_sampler, tmpUV.xy) * 2.0f - 1.0f;
		tmpNormal = normalize(tmpNormal);
		tmpNormal.w = 0;
		tmpNormal.a = 1;
		//return tmpNormal;

		float4 NL = clamp(dot(normalize(inData.light), tmpNormal), 0.5,1);
		float4 reflection = reflect(inData.light, tmpNormal);
		float4 specular = pow(saturate(dot(reflection, inData.Neyev)), shininess) * specularColor;

		if (isTextured != 0) {
			diffuse = g_texture.Sample(g_sampler, inData.uv) * NL;
			ambient = g_texture.Sample(g_sampler, inData.uv) * ambientColor;
		}
		else {
			diffuse = diffuseColor * NL;
			ambient = diffuseColor * ambientColor;
		}
		return diffuse + specular + ambient;
	}
	else
	{
		float4 reflection = reflect(normalize(lightPosition), inData.normal);

		float4 specular = pow(saturate(dot(normalize(reflection), inData.eyev)), shininess) * specularColor;
		if (isTextured == 0) {
			diffuse = lightSource * diffuseColor * inData.color;
			ambient = lightSource * diffuseColor * ambientColor;
		}
		else {
			diffuse = lightSource * g_texture.Sample(g_sampler, inData.uv) * inData.color;
			ambient = lightSource * g_texture.Sample(g_sampler, inData.uv) * ambientColor;
		}
		return diffuse + specular + ambient;
	}
}

////───────────────────────────────────────
//// ピクセルシェーダ
////───────────────────────────────────────
//float4 PS(VS_OUT inData) : SV_Target
//{
//	float4 lightSource = float4(1.0, 1.0, 1.0, 1.0);
//	float4 diffuse;
//	float4 ambient;
//
//	float2 tmpuv = inData.uv;
//	tmpuv.x = tmpuv.x + scrollx;
//	tmpuv.y = tmpuv.y + scrolly;
//
//
//	if (isNormalMap)
//	{
//		inData.light = normalize(inData.light);
//		float4 tmpNormal = normalTex.Sample(g_sampler, tmpuv.xy) * 2.0f - 1.0f;
//		tmpNormal = normalize(tmpNormal);
//		tmpNormal.w = 0;
//		tmpNormal.a = 1;
//		
//		
//
//			
//			//return tmpNormal;
//		float4 NL = clamp(dot(inData.light, tmpNormal), 0.5, 1);
//
//		float4 reflection = reflect(-inData.light, tmpNormal);
//		float4 specular = pow(saturate(dot(normalize(reflection), inData.eyev)), shininess) * specularColor;
//
//		if (isTextured != false)
//		{
//			diffuse = g_texture.Sample(g_sampler, inData.uv) * NL;
//			ambient = g_texture.Sample(g_sampler, inData.uv) * ambientColor;
//		}
//		else
//		{
//			diffuse = diffuseColor * NL;
//			ambient = diffuseColor * ambientColor;
//		}
//		return   diffuse+specular+ambient;
//	}
//	else
//	{
//		
//
//		//return tmpNormal;
//		float4 reflection = reflect(normalize(lightPosition), inData.normal);
//
//		float4 specular = pow(saturate(dot(normalize(reflection), inData.eyev)), shininess) * specularColor;
//		if (isTextured == false)
//		{
//			diffuse = lightSource * diffuseColor * inData.color;
//			ambient = lightSource * diffuseColor * ambientColor;
//		}
//		else
//		{
//			diffuse = lightSource * g_texture.Sample(g_sampler, tmpuv) * inData.color;
//			ambient = lightSource * g_texture.Sample(g_sampler, tmpuv) * ambientColor;
//		}
//		return   diffuse+ambient;
//		/*float4 result = diffuse + ambient + specular;
//		if (isTextured)
//			result.a = inData.uv;
//		return result;*/
//	}
//}