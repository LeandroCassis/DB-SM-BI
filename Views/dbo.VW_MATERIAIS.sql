SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_MATERIAIS] 
AS SELECT

Material.Id 'ID MATERIAL',
UPPER(Material.Descricao) 'MATERIAL',
Material.IdGrupoMaterial 'ID GRUPO MATERIAL',
UPPER(COALESCE(GrupoMaterial.Descricao, 'SEM GRUPO')) 'GRUPO MATERIAL'
--,GRUPO_MACRO_MATERIAIS.[MACRO GRUPO]


FROM RajaMine.dbo.Material WITH (NOLOCK) 

LEFT JOIN RajaMine.dbo.GrupoMaterial WITH (NOLOCK)
ON Material.IdGrupoMaterial = GrupoMaterial.Id
AND Material.IdEmpresa = GrupoMaterial.IdEmpresa
--
--LEFT JOIN  GRUPO_MACRO_MATERIAIS WITH (NOLOCK)
--ON GrupoMaterial.Id = GRUPO_MACRO_MATERIAIS.[ID GRUPO MATERIAL]
GO