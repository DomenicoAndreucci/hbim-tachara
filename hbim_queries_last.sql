-- ==========================================================
-- HBIM Tachara — Query Pack (Generale + HBIM_Activity)
-- DB: hbim_tachara.db
-- Tabelle: documents, doc_links, elements, guid_maps
-- Vis­te:   v_search, v_docs_year
-- NBper me: per le query Activity si assume io abbia lanciato:
--   python upgrade_db_activity.py --db hbim_tachara.db --master work_enrichment_v3.csv
-- che aggiunge i campi Activity a 'elements' e ricrea v_search e l'ultimo fix del bug su vista search.
-- ==========================================================

-- 0) Sanità di base
SELECT COUNT(*) AS n_documents FROM documents;
SELECT COUNT(*) AS n_doc_links FROM doc_links;
SELECT COUNT(*) AS n_elements   FROM elements;
SELECT COUNT(*) AS n_guid_maps  FROM guid_maps;

-- 1) Anteprima 'search' (per GUID)
SELECT ifc_guid, label, element_type, photo_date_min, photo_date_max, photo_count,
       photographers, owners, photo_classes, collection_url, manifest_url
FROM v_search
LIMIT 20;

-- 2) GUID con Mirador attivo
SELECT ifc_guid, label, manifest_url
FROM v_search
WHERE manifest_url IS NOT NULL
ORDER BY label
LIMIT 50;

-- 3) Solo Collections (no Mirador)
SELECT COUNT(*) AS guids_only_collections
FROM v_search
WHERE collection_url IS NOT NULL AND manifest_url IS NULL;

-- 4) Doorjamb (esempio label)
SELECT ifc_guid, label, photo_count, collection_url, manifest_url
FROM v_search
WHERE label LIKE '%Doorjamb%'
ORDER BY photo_count DESC;

-- 5) Fotografo specifico (es. Faccenna)
SELECT DISTINCT ifc_guid, label, photographers
FROM v_search
WHERE photographers LIKE '%Faccenna%'
ORDER BY label;

-- 6) Proprietario specifico (es. ISMEO)
SELECT DISTINCT ifc_guid, label, owners
FROM v_search
WHERE owners LIKE '%ISMEO%'
ORDER BY label;

-- 7) Serie temporale globale (scatto per anno)
SELECT year, COUNT(*) AS photos
FROM documents
WHERE year IS NOT NULL
GROUP BY year
ORDER BY year;

-- 8) Serie temporale per elemento (foto per GUID/anno)
SELECT ifc_guid, year, n_photos
FROM v_docs_year
ORDER BY ifc_guid, year;

-- 10)  GUID privi di Mirador
SELECT ifc_guid, label, collection_url, manifest_url
FROM v_search
WHERE collection_url IS NULL OR manifest_url IS NULL
ORDER BY label
LIMIT 50;


-- 12) Elenco foto per un GUID specifico  <-- sostituire il <GUID>
SELECT d.photo_id, d.year, d.photographer, d.owner, d.url
FROM doc_links l JOIN documents d ON d.photo_id = l.photo_id
WHERE l.ifc_guid = '<GUID>'
ORDER BY d.year, d.photo_id;

-- 13) GUID con foto tra 1960 e 1971
SELECT DISTINCT v.ifc_guid
FROM v_docs_year v
WHERE v.year BETWEEN 1960 AND 1971
ORDER BY v.ifc_guid;

-- ===========================
-- HBIM_Activity — Query Pack
-- Campi (in 'elements' e v_search):
--   has_restoration, restoration_period
--   has_excavation,  excavation_period
--   has_spoliation_attempt, has_spoliation_success, spoliation_period
--   reused_at, reused_coords, relocated_back_year, relocated_by
-- ===========================

-- A1) Conteggi globali flag
SELECT
  SUM(CASE WHEN has_restoration='Yes'        THEN 1 ELSE 0 END) AS n_restoration,
  SUM(CASE WHEN has_excavation='Yes'         THEN 1 ELSE 0 END) AS n_excavation,
  SUM(CASE WHEN has_spoliation_attempt='Yes' THEN 1 ELSE 0 END) AS n_spo_attempt,
  SUM(CASE WHEN has_spoliation_success='Yes' THEN 1 ELSE 0 END) AS n_spo_success
FROM elements;

-- A2) Elenco elementi con RESTURo
SELECT ifc_guid, label, restoration_period, collection_url, manifest_url
FROM v_search
WHERE has_restoration='Yes'
ORDER BY label
LIMIT 100;

-- A3) Elenco elementi con SCAVO
SELECT ifc_guid, label, excavation_period, collection_url, manifest_url
FROM v_search
WHERE has_excavation='Yes'
ORDER BY label
LIMIT 100;

-- A4) Spoliazione: tentativi e successi
SELECT ifc_guid, label, has_spoliation_attempt, has_spoliation_success, spoliation_period
FROM v_search
WHERE has_spoliation_attempt='Yes' OR has_spoliation_success='Yes'
ORDER BY label;

-- A5) Reuse - Relocation
SELECT ifc_guid, label, reused_at, reused_coords, relocated_back_year, relocated_by
FROM v_search
WHERE COALESCE(reused_at,'') <> '' OR COALESCE(relocated_back_year,'') <> ''
ORDER BY label;

-- A6) Intersezione: RESTAURO + foto anni '60–'70
SELECT DISTINCT s.ifc_guid, s.label, s.restoration_period, v.year
FROM v_search s
JOIN v_docs_year v ON v.ifc_guid = s.ifc_guid
WHERE s.has_restoration='Yes' AND v.year BETWEEN 1960 AND 1979
ORDER BY s.ifc_guid, v.year;

-- A7) SPOILIAZIONE (success) + Mirador
SELECT ifc_guid, label, has_spoliation_success, manifest_url
FROM v_search
WHERE has_spoliation_success='Yes' AND manifest_url IS NOT NULL;

-- A8) Doorjamb con SCAVO e/o RESTAURO
SELECT ifc_guid, label, has_excavation, has_restoration, collection_url, manifest_url
FROM v_search
WHERE label LIKE '%Doorjamb%'
  AND (has_excavation='Yes' OR has_restoration='Yes')
ORDER BY label;

-- A9) Conteggi per LABEL 
SELECT
  CASE
    WHEN label LIKE '%Doorjamb%'   THEN 'Doorjamb'
    WHEN label LIKE '%Architrave%' THEN 'Architrave'
    WHEN label LIKE '%Cornice%'    THEN 'Cornice'
    WHEN label LIKE '%Human%'     THEN 'Human'
    WHEN label LIKE '%Lion%'       THEN 'Lion'
    ELSE 'Other'
  END AS class_bucket,
  SUM(CASE WHEN has_restoration='Yes'        THEN 1 ELSE 0 END) AS n_restoration,
  SUM(CASE WHEN has_excavation='Yes'         THEN 1 ELSE 0 END) AS n_excavation,
  SUM(CASE WHEN has_spoliation_attempt='Yes' THEN 1 ELSE 0 END) AS n_spo_attempt,
  SUM(CASE WHEN has_spoliation_success='Yes' THEN 1 ELSE 0 END) AS n_spo_success,
  SUM(CASE WHEN TRIM(COALESCE(has_museum,'')) <> '' THEN 1 ELSE 0 END) AS n_museum,
  COUNT(*) AS n_elements
FROM v_search
GROUP BY class_bucket
ORDER BY n_elements DESC;


