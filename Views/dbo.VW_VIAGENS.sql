SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_VIAGENS] 
AS SELECT
 Empresa.Descricao 'EMPRESA'
 ,v.Id 'ID VIAGEM'
 ,v.IdOperador 'ID OPERADOR VIAGEM'
 ,v.IdEquipamentoTransporte 'ID EQUIPAMENTO TRANSPORTE'
 ,v.IdEquipamentoCarga 'ID EQUIPAMENTO CARGA'
 ,v.IdMaterial 'ID MATERIAL'
 ,e.Placa 'PLACA'
 ,UPPER(mat.Descricao) 'MATERIAL'
 ,mat.IdGrupoMaterial 'ID GRUPO MATERIAL'
 ,UPPER(COALESCE(GrupoMaterial.Descricao, 'OCORRÊNCIA SEM VIAGEM')) 'GRUPO MATERIAL'
 ,UPPER(COALESCE(GRUPO_MACRO_MATERIAIS.[MACRO GRUPO], 'GRUPO NÃO CLASSIFICADO')) 'GRUPO MACRO MATERIAL'
 ,UPPER(ori.Descricao) 'ORIGEM'
 ,UPPER(dest.Descricao) 'DESTINO'
 ,UPPER(e.Descricao) 'EQUIPAMENTO'
 ,UPPER(o.Nome) 'OPERADOR'
 ,v.TempoVazio / 3600.0 '#TEMPO VAZIO'
 ,v.TempoCheio / 3600.0 '#TEMPO CHEIO'
 ,v.InicioViagem 'DATA INÍCIO VIAGEM'
  ,v.FimBascula 'DATA FIM VIAGEM'
 ,v.InicioFilaVazio 'DATA INÍCIO FILA VAZIO'
 ,v.FimFilaVazio 'DATA FIM FILA VAZIO'
 ,v.TempoFilaCarga / 3600.0 '#TEMPO FILA VAZIO'
 ,v.InicioManobraVazio 'DATA INÍCIO MANOBRA VAZIO'
 ,v.FimManobraVazio 'DATA FIM MANOBRA VAZIO'
 ,v.TempoManobraVazio / 3600.0 '#TEMPO MANOBRA VAZIO'
 ,v.InicioCarga 'DATA INÍCIO CARGA'
 ,v.FimCarga 'DATA FIM CARGA'
 ,v.TempoCarregando / 3600.0 'TEMPO CARREGANDO'
 ,v.InicioFilaCheio 'DATA INÍCIO CHEIO'
 ,v.FimFilaCheio 'FIM FILA CHEIO'
 ,v.TempoFilaBasculamento / 3600.0 '#TEMPO FILA BASCULAMENTO'
 ,v.InicioManobraCheio 'DATA INÍCIO MANOBRA CHEIO'
 ,v.FimManobraCheio 'DATA FIM MANOBRA CHEIO'
 ,v.TempoManobraCheio / 3600.0 '#TEMPO MANOBRA CHEIO'
 ,v.InicioBascula 'DATA INÍCIO BASCULA'
 ,v.FimBascula 'DATA FIM BASCULA'
 ,v.TempoDescarregando / 3600.0 '#TEMPO DESCARREGANDO'
 ,v.TempoViagem / 3600.0 '#TEMPO VIAGEM'
 ,v.Carga '#CARGA'
 ,SUBSTRING(REPLACE(STUFF((SELECT
      UPPER(toc.Descricao) + ' (' + CAST(FORMAT(ROUND(oc.SegundosOcorrencias / 60.0, 2), 'N2') AS VARCHAR) + ' MIN)' + CHAR(10)
    FROM RajaMine.dbo.Ocorrencia oc
    INNER JOIN RajaMine.dbo.TipoOcorrencia toc
      ON toc.Id = oc.IdTipoOcorrencia
    WHERE oc.IdViagem = v.Id
    ORDER BY oc.Data
    FOR XML PATH (''))
  , 1, 0, CHAR(10)), '&amp;#x0D;', ''), 2, 2000) 'OCORRÊNCIAS'
 ,(SELECT
      SUM(SegundosOcorrencias / 3600.0)
    FROM RajaMine.dbo.Ocorrencia oc
    WHERE oc.IdViagem = v.Id)
  '#TEMPO PARADO'
 ,(SELECT
      SUM(SegundosOcorrencias / 3600.0)
    FROM RajaMine.dbo.Ocorrencia oc
    INNER JOIN RajaMine.dbo.TipoOcorrencia toc
      ON toc.Id = oc.IdTipoOcorrencia
    INNER JOIN RajaMine.dbo.ClasseOcorrencia cl
      ON cl.Id = toc.IdClasseOcorrencia
    WHERE oc.IdViagem = v.Id
    AND cl.DescontaHorasViagem = 'S')
  '#TEMPO PARADO NÃO CONTABILIZADO'
  -- ,ISNULL(odMeta.MetaTempoCiclo, 0) / 60.0 MetaTempoCiclo
  -- ,Meta.MetaTempoStatus0 / 60.0 MetaTempoVazio
  -- ,Meta.MetaTempoStatus1 / 60.0 MetaTempoCheio
  -- ,Meta.MetaTempoStatus2 / 60.0 MetaTempoCarregando
  -- ,Meta.MetaTempoStatus3 / 60.0 MetaTempoBasculando
  -- ,Meta.MetaTempoStatus4 / 60.0 MetaTempoEmFila
  -- ,Meta.MetaTempoStatus5 / 60.0 MetaTempoEmManobra
 ,v.DistanciaVazio / 1000.0 '#DISTANCIA VAZIO'
 ,v.DistanciaCheio / 1000.0 'DISTANCIA CHEIO'
 ,IIF(CHARINDEX('CAVA', UPPER(ori.Descricao)) > 0, 'CAVAS', 'OUTRAS') 'TIPO ORIGEM'

 ,REPLACE(IIF(v.LatitudeInicioViagem=0,NULL,v.LatitudeInicioViagem),',','.') 'LATITUDE INÍCIO VIAGEM'
 ,REPLACE(IIF(v.LongitudeInicioViagem=0,NULL,v.LongitudeInicioViagem),',','.') 'LONGITUDE INÍCIO VIAGEM'

,UPPER(Turno.Descricao) 'TURNO'



FROM RajaMine.dbo.Viagem v
LEFT OUTER JOIN RajaMine.dbo.Equipamento e
  ON e.Id = v.IdEquipamentoTransporte
LEFT OUTER JOIN RajaMine.dbo.Operador o
  ON o.Id = v.IdOperador
LEFT OUTER JOIN RajaMine.dbo.Local ori
  ON ori.Id = v.IdOrigem
INNER JOIN RajaMine.dbo.Local dest
  ON dest.Id = v.IdDestino
INNER JOIN RajaMine.dbo.Material mat
  ON mat.Id = v.IdMaterial
LEFT OUTER JOIN RajaMine.dbo.Meta
  ON Meta.IdTurno = v.IdTurno
    AND e.IdTipoEquipamento = Meta.IdTipoEquipamento
LEFT OUTER JOIN RajaMine.dbo.OrigemDestino od
  ON od.IdOrigem = v.IdOrigem
    AND od.IdDestino = v.IdDestino
LEFT OUTER JOIN RajaMine.dbo.OrigemDestinoxMeta odMeta
  ON odMeta.IdMeta = Meta.Id
    AND od.Id = odMeta.IdOrigemDestino

LEFT JOIN RajaMine.dbo.GrupoMaterial WITH (NOLOCK)
  ON mat.IdGrupoMaterial = GrupoMaterial.Id

LEFT JOIN  GRUPO_MACRO_MATERIAIS WITH (NOLOCK)
ON GrupoMaterial.Id = GRUPO_MACRO_MATERIAIS.[ID GRUPO MATERIAL]

LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)
ON e.IdEmpresa = Empresa.Id 


LEFT JOIN RajaMine.dbo.Turno 
ON V.IdTurno = Turno.Id

WHERE v.Ano >= 2024


--SELECT
-- Viagem.Id 'ID VIAGEM'
--,Viagem.IdOperador 'ID OPERADOR VIAGEM'
--,CAST(InicioViagem AS DATE) 'DATA VIAGEM'
--,UPPER(COALESCE(_OPERADOR_VIAGEM.Nome,'OCORRÊNCIA SEM VIAGEM')) 'OPERADOR VIAGEM'
--,Viagem.IdOrigem 'ID ORIGEM'
--,CONCAT_WS('-', _ORIGEM.Id,UPPER(_ORIGEM.Descricao)) 'ORGINEM'
--,Viagem.IdDestino 'ID DESTINO'
--,CONCAT_WS('-', _DESTINO.Id,UPPER(_DESTINO.Descricao)) 'DESTINO'
--,Viagem.IdEquipamentoTransporte 'ID EQUIPAMENTO TRANSPORTE'
--,Viagem.IdEquipamentoCarga 'ID EQUIPAMENTO CARGA'
--,Viagem.IdMaterial 'ID MATERIAL'
--,UPPER(COALESCE(Material.Descricao,'OCORRÊNCIA SEM VIAGEM')) 'MATERIAL'
--,Material.IdGrupoMaterial 'ID GRUPO MATERIAL'
--,UPPER(COALESCE(GrupoMaterial.Descricao,'OCORRÊNCIA SEM VIAGEM')) 'GRUPO MATERIAL'
--,ISNULL(Viagem.Carga, 0) '#CARGA'
--
--
--FROM RajaMine.dbo.Viagem   WITH (NOLOCK)
--
--
--LEFT JOIN RajaMine.dbo.Escala WITH (NOLOCK)
--  ON Viagem.IdEscala = Escala.Id
--
--LEFT JOIN RajaMine.dbo.Operador _OPERADOR_VIAGEM WITH (NOLOCK)
--  ON Viagem.IdOperador = _OPERADOR_VIAGEM.Id
--
--
--LEFT JOIN RajaMine.dbo.Material WITH (NOLOCK) 
--ON Viagem.IdMaterial = Material.Id
--
--LEFT JOIN RajaMine.dbo.GrupoMaterial WITH (NOLOCK)
--ON Material.IdGrupoMaterial = GrupoMaterial.Id
--
--
--LEFT JOIN RajaMine.dbo.Local _DESTINO  WITH (NOLOCK) 
--ON Viagem.IdDestino = _DESTINO.Id
--
--LEFT JOIN RajaMine.dbo.Local _ORIGEM  WITH (NOLOCK) 
--ON Viagem.IdOrigem = _ORIGEM.Id
--
----WHERE v.FimBascula IS NOT NULL
--WHERE Viagem.Ano = 2024
GO