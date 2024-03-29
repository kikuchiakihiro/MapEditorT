#include "Ball.h"
#include "Engine/sprite.h"
#include "Engine/Model.h"
#include "Engine/Fbx.h"
#include "Engine/Transform.h"
//コンストラクタ
Ball::Ball(GameObject* parent)
    :GameObject(parent, "Ball"),hModel_(-1)
{
}

//デストラクタ
Ball::~Ball()
{
}
Sprite* pSprite = nullptr;
//初期化
void Ball::Initialize()
{
    //モデルデータのロード
    hModel_ = Model::Load("Assets/Ball.fbx");
    assert(hModel_ >= 0);
    //transform_.position_.y = 1;
   transform_.scale_ = { 3.0,3.0,3.0 };
}

//更新
void Ball::Update()
{
    transform_.position_.y = 3;
    transform_.position_.z = 3;
}

//描画
void Ball::Draw()
{
    Model::SetTransform(hModel_, transform_);
    Model::Draw(hModel_);
}

//開放
void Ball::Release()
{
}