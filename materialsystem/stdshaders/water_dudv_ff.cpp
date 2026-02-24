//========= Copyright Valve Corporation, All rights reserved. ============//
//
// Purpose: DX6 fixed-function fallback for Water_DuDv.
//          The DX8+ shader renders refraction distortion using a dudv bump map
//          and VS/PS. In fixed-function we cannot distort, so we simply blit
//          the refraction render target tinted by $refracttint.
//
// $NoKeywords: $
//=============================================================================//

#include "shaderlib/cshader.h"

// memdbgon must be the last include file in a .cpp file!!!
#include "tier0/memdbgon.h"

DEFINE_FALLBACK_SHADER( Water_DuDv, Water_DuDv_FF )

BEGIN_SHADER( Water_DuDv_FF, "Help for Water_DuDv_FF" )

	BEGIN_SHADER_PARAMS
		SHADER_PARAM( BUMPMAP,       SHADER_PARAM_TYPE_TEXTURE, "", "dudv bump map (unused in FF)" )
		SHADER_PARAM( BUMPFRAME,     SHADER_PARAM_TYPE_INTEGER, "0", "frame number for $bumpmap" )
		SHADER_PARAM( BUMPTRANSFORM, SHADER_PARAM_TYPE_MATRIX, "center .5 .5 scale 1 1 rotate 0 translate 0 0", "$bumpmap texcoord transform" )
		SHADER_PARAM( REFRACTAMOUNT, SHADER_PARAM_TYPE_FLOAT,  "0", "" )
		SHADER_PARAM( REFRACTTINT,   SHADER_PARAM_TYPE_COLOR,  "[1 1 1]", "refraction tint" )
	END_SHADER_PARAMS

	SHADER_INIT_PARAMS()
	{
		if ( !params[REFRACTTINT]->IsDefined() )
		{
			params[REFRACTTINT]->SetVecValue( 1.0f, 1.0f, 1.0f );
		}
	}

	SHADER_INIT
	{
		// Bumpmap is unused in FF path but load it anyway to avoid missing texture warnings.
		if ( params[BUMPMAP]->IsDefined() )
		{
			LoadTexture( BUMPMAP );
		}
	}

	SHADER_DRAW
	{
		SHADOW_STATE
		{
			// Write alpha so the water surface alpha is correct.
			pShaderShadow->EnableAlphaWrites( true );
			pShaderShadow->EnableColorWrites( true );

			// Bind the refraction render target on sampler 0.
			pShaderShadow->EnableTexture( SHADER_SAMPLER0, true );

			// Modulate the refraction texture by $refracttint via the color modulation.
			SetModulationShadowState();
			SetNormalBlendingShadowState();

			pShaderShadow->DrawFlags( SHADER_DRAW_POSITION | SHADER_DRAW_TEXCOORD0 );
			DisableFog();
		}
		DYNAMIC_STATE
		{
			// Bind the refraction render target (same slot the DX8 shader uses).
			pShaderAPI->BindStandardTexture( SHADER_SAMPLER0, TEXTURE_FRAME_BUFFER_FULL_TEXTURE_0 );

			// Apply $refracttint as the color modulation.
			float tint[3];
			params[REFRACTTINT]->GetVecValue( tint, 3 );
			pShaderAPI->Color3fv( tint );
		}
		Draw();
	}
END_SHADER
