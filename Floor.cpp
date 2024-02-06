#include "Floor.h"
#include "Engine/sprite.h"
#include "Engine/Model.h"
#include "Engine/Fbx.h"
#include "Engine/Transform.h"
//�R���X�g���N�^
Floor::Floor(GameObject* parent)
    :GameObject(parent, "Floor"), hModel_(-1)
{
}

//�f�X�g���N�^
Floor::~Floor()
{
}
Sprite* pSprite = nullptr;
//������
void Floor::Initialize()
{
    //���f���f�[�^�̃��[�h
    hModel_ = Model::Load("Assets/WaterNomral.fbx");
    assert(hModel_ >= 0);
    transform_.position_.z = -8;
    transform_.position_.y = 5;
   
}

//�X�V
void Floor::Update()
{
    /*transform_.rotate_.z += 0.1;
    transform_.rotate_.y += 0.1;*/
}

//�`��
void Floor::Draw()
{
    Model::SetTransform(hModel_, transform_);
    Model::Draw(hModel_);
}

//�J��
void Floor::Release()
{
}