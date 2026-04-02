SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[WH_QUALIDADE_POR_PROCESSO] AS

WITH BaseQuery AS (
SELECT --TOP 100
 t.IdEmpresa 'COD EMPRESA'
 ,UPPER(tp.descricao) 'TIPO PROCESSO'
 ,cast(pr.Data as date)  'DATA'
 ,pr.Massa 'TONELADAS'
 ,pr.TempoProcessamento 'TEMPO PROCESSAMENTO'
 ,UPPER(t.Descricao) 'TURNO'
 ,ISNULL(pr.AnaliseQuimicaInformada, 'S') 'ANÁLISE INFORMADA'
 ,ISNULL(pr.AnaliseGranulometricaInformada, 'S') 'ANÁLISE GRANOLOMÉTRICA INFORMADA'
 ,pr.EL1
 ,pr.EL2
 ,pr.EL3
 ,pr.EL4
 ,pr.EL5
 ,pr.EL6
 ,pr.EL7
 ,--QuÃ­mica
  pr.EL8
 ,pr.EL9
 ,pr.EL10
 ,pr.EL11
 ,pr.EL12
 ,pr.EL13
 ,pr.EL14
 ,pr.EL15
 ,pr.EL16
 ,pr.EL17
 ,--GranulomÃ©trica
  (SELECT
      e.Sigla
    FROM  RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL1'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl1
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL2'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl2
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL3'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl3
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL4'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl4
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL5'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl5
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL6'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl6
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL7'
    AND e.Tipo = 0--QuÃ­mica
  )
  NomeEl7
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL8'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl8
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL9'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl9
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL10'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl10
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL11'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl11
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL12'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl12
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL13'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl13
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL14'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl14
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL15'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl15
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL16'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl16
 ,(SELECT
      e.Sigla
    FROM RajaMine.dbo.ElementoXTipoProcesso etp
    INNER JOIN RajaMine.dbo.Elemento e
      ON e.id = etp.IdElemento
    WHERE etp.IdTipoProcesso = pr.IdTipoProcesso
    AND e.Campo = 'EL17'
    AND e.Tipo = 1--GranulomÃ©trica
  )
  NomeEl17
FROM RajaMine.dbo.Processo pr
INNER JOIN RajaMine.dbo.TipoProcesso tp
  ON tp.Id = pr.IdTipoProcesso
INNER JOIN RajaMine.dbo.PlantaTurno t
  ON t.Id = pr.IdPlantaTurno
)
SELECT 
  [COD EMPRESA],
  [TIPO PROCESSO],
  [DATA],
  [TONELADAS],
  [TEMPO PROCESSAMENTO],
  [TURNO],
  [ANÁLISE INFORMADA],
  [ANÁLISE GRANOLOMÉTRICA INFORMADA],
  U.VALOR,
  U.ELEMENTO
FROM BaseQuery
CROSS APPLY (
  VALUES 
    (EL1, NomeEl1),
    (EL2, NomeEl2),
    (EL3, NomeEl3),
    (EL4, NomeEl4),
    (EL5, NomeEl5),
    (EL6, NomeEl6),
    (EL7, NomeEl7),
    (EL8, NomeEl8),
    (EL9, NomeEl9),
    (EL10, NomeEl10),
    (EL11, NomeEl11),
    (EL12, NomeEl12),
    (EL13, NomeEl13),
    (EL14, NomeEl14),
    (EL15, NomeEl15),
    (EL16, NomeEl16),
    (EL17, NomeEl17)
) U(VALOR, ELEMENTO)
WHERE U.VALOR IS NOT NULL AND U.VALOR <> 0
GO