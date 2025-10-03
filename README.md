# HBIM Tachara – Photographic Pipeline and Data Layer

## Summary
Integration of historical and modern photographs of the Palace of Darius, Tachara, of Persepolis into the HBIM workflow.   
Proof of Concept status:  
- PoC-A (IFC with PSet and DocumentReference): completed.  
- PoC-B (Collections HTML): completed.  
- PoC-C (IIIF/Mirador): partial, limited to a public subset.  
- SQLite database (`hbim_tachara.db`): available.  
- Advanced PSet (Inscriptions, Restorations, Deterioration): not implemented.  
- GlobalId handling for composite elements: non-standard solution.

---

## 1. Context
This work is part of the doctoral research at the University of Turin of Domenico Andreucci.  
The main objectives are:  
- integrate historical and modern photographs into the HBIM model;  
- enable diachronic and transparent consultation of images;  
- develop a protocol aligned with IFC standards (buildingSMART International 2023).  
  *Note:* The work is aligned with IFC standards; the model is currently exported as IFC2x3 (compatibility with Archicad and IfcOpenShell), while methodological choices follow IFC 4.3.2.0.
- align the web/document layer with IIIF Presentation API 3.0 (IIIF, 2020),  
  CIDOC-CRM v7.1.x (ISO 21127:2023), and Getty AAT/SKOS LOD.  
- build a SQLite data layer for chronological and typological queries.

## 1.a Nature of the Model

This HBIM representation is conceived not as a precise historical reconstruction of a specific temporal phase, but as a **conceptual model** tailored to the needs of semantic annotation and machine learning datasets (e.g. PeRSeg 14).  
Only the classes and elements relevant to the CNN dataset were richly annotated; the rest remain geometrical placeholders without full enrichment.  
Modeling decisions are based on from standard references — *Persepolis I: Structures, Reliefs, Inscriptions* (Schmidt), *Travaux de Restauration* (Zander, ed.), and *Studies and Restorations* (Tilia) — and were adjusted using modern photos to fill gaps in documentation.  

---

## 2. Repository Resources
- **Enriched IFC**: [`tachara_links_v3_clean.ifc`](tachara_links_v3_clean.ifc)  
- **Per-element enrichment CSV**: [`work_enrichment_v3.csv`](work_enrichment_v3.csv)  
- **Collections map**: [`collections_map.csv`](collections_map.csv)  
- **Manifests map**: [`manifests_map.csv`](manifests_map.csv)  
- **SQLite database**: [`hbim_tachara.db`](hbim_tachara.db)  
- **Web directories**:  
  - `/collections/` – HTML pages per element  
  - `/manifests/` – IIIF P3 manifests  
  - `/media/` – subset of public images  
- **Consultation pages**:  
  - [search.html](https://domenicoandreucci.github.io/hbim-tachara/search.html?v=20) (integrated search)  
  - `mirador.html` (IIIF viewer with `?manifest=` parameter).
- **BCF demo**: `Diacronic_View_P10.bcf`  

---

## 3. Implemented Pipeline

The pipeline was developed in Python 3.11, using dedicated scripts primarily based on  
IfcOpenShell (for IFC manipulation), the standard sqlite3 library (for the relational DB),  
and common Python modules (csv, json, argparse, etc.).

Each step is idempotent, meaning it can be re-run without introducing duplicates,  
and it relies on standard IFC/CSV files.

---

## 3.1 Writing HBIM_* PropertySets (PoC-A) 

- **Script:** `apply_pset_from_enrichment.py`  
- **Libraries:** `ifcopenshell`, `csv`  
- **Input:** IFC base (`tachara_ready.ifc`), `work_enrichment_v3.csv`  
- **Output:** IFC with HBIM_* PropertySets (`HBIM_Doc`, `HBIM_Type`, `HBIM_Heritage`, etc.)  
- **Function:** Properties from the enrichment CSVs are written into PropertySets (in IFC2x3, URLs fall back to IfcText).
---

## 3.2 Normalizing Names and Classifications (PoC-A)  

- **Script:** `set_names_types_from_master.py`  
- **Libraries:** `ifcopenshell`, `csv`  
- **Input:** Enriched IFC, `work_enrichment_v3.csv`  
- **Output:** IFC with  
  - `IfcElement.Name` (from *name_suggested*)  
  - `IfcElement.ObjectType` (from *label*)  
  - External classifications (`IfcRelAssociatesClassification`) linked to AAT/SKOS  
- **Function:** Consistent naming and semantic associations are ensured through links to international thesauri.

---

## 3.3 Linking Photographs (DocumentReference, PoC-A) 

- **Script:** `make_docrefs_from_manifest_ifcaware.py`  
- **Libraries:** `ifcopenshell`, `csv`, `re`  
- **Input:** Updated IFC, `DocManifest_TEMPLATE_normalized.csv` (photo→GUID map)  
- **Output:** IFC with `IfcDocumentReference` and `IfcRelAssociatesDocument` for each photo  
- **Function:**  
  - Links each image to IFC elements  
  - Automatically converts Google Drive links into direct links  
  - Exports CSV of missing GUIDs

---

## 3.4 Generating HTML Collections (PoC-B)

- **Script:** `generate_collections.py`  
- **Libraries:** `csv`, `html`  
- **Input:** Manifest CSV, `work_enrichment_v3.csv`  
- **Output:** `/collections/*.html`, `collections_map.csv`, `index.html`  
- **Function:** HTML pages are produced for each GUID, including:  
  - Photo gallery  
  - Year  
  - Author  
  - Owner  
  - Inline previews

---

## 3.5 Creating IIIF P3 Manifests (PoC-C)

- **Script:** `generate_iiif_from_media.py`  
  *(or `generate_iiif_manifests_strict.py` for authorized subsets)*  
- **Libraries:** `csv`, `json`, `argparse`  
- **Input:** Manifest CSV, enrichment CSV, `/media/` folder  
- **Output:** `/manifests/*.json`, `manifests_map.csv`  
- **Function:** IIIF manifests are generated compatible with **Mirador**,  
  enabling diachronic comparison of images.

---

## 3.6 Building the Relational Database (extension of PoC-B/C) 

- **Script:** `build_hbim_db.py`  
- **Libraries:** `sqlite3`, `csv`  
- **Input:** Manifest CSV, enrichment CSV, `collections_map.csv`, `manifests_map.csv`  
- **Output:** `hbim_tachara.db`  
- **Function:** A lightweight AIM (Asset Information Model) is created with:  
-- **Tables:** `documents`, `doc_links`, `elements`, `guid_maps`  
-- **Views:**  
   - `v_search` → integrates element metadata with links to collections/manifests  
   - `v_docs_year` → chronological series of photos per GUID  
- Supports both typological and diachronic queries.



---

## 3.7 Preparing Data for the Web Viewer (support for PoCs) 

- **Script:** `build_viewer_data_plus_v2.py`  
- **Libraries:** `csv`, `json`  
- **Input:** Enrichment CSV, manifest CSV, collections/manifests maps  
- **Output:** `viewer_data_full.json`  
- **Function:** JSON consumed by [search.html](https://domenicoandreucci.github.io/hbim-tachara/search.html?v=20)  
  for integrated online consultation (filters by year, photographer, owner, activity, etc.).

---


---

## 4. Results
- Enriched and cleaned IFC, with AAT/SKOS classifications and consistent DocumentReferences.  
- 406 HTML pages generated (Collections).  
- 10 valid IIIF manifests usable in Mirador.  
- SQLite database supporting chronological, typological, photographer/owner queries.

---

## 5. Current Limitations
- PoC-C incomplete: only public subset of images.  
- Masks/JSON annotations not yet integrated.  
- Inscriptions scarcely populated; Restorations and Deterioration not implemented.  
- Missing PhotoPose/camera coordinates.  
- GlobalId handling for composite elements: non-standard solution
- IfcSite coordinates approximate.  
- AAT/SKOS URIs need consolidation.  



### Note on Image Rights
The public subset of images in /media/ consists exclusively of photographs for which full copyright is held by the author. The subset has been published only as a technical **proof-of-concept**, demonstrating how the workflow could support FAIR and open access dissemination if copyright restrictions were lifted in the future.  
Most archival photographs referenced in the database remain subject to restrictive copyright conditions and are therefore not distributed here.   



#### Note on GUIDs and Composite Elements

All GlobalIds (GUIDs) in the IFC model are formally valid. However, certain architectural elements—specifically architrave trims and doorjambs, were originally modeled in Archicad as composite pillars, not separate sub-elements. 
During IFC export, software generates **derived GUIDs** for the split parts, resulting in additional, automatically generated identifiers. 
In downstream viewers, these parts may appear as distinct elements with separate GUIDs. To maintain associativity, shared information has been duplicated: for example, the aggregated element A+B carries the same metadata as the individual parts A and B. This non-standard but pragmatic solution has been adopted to allow more granular linking without breaking referential consistency.




---

## 6. Next Steps
- Extend DocumentReference to masks and JSON files.  
- Populate HBIM_Inscription with transcriptions/TEI.  
- Implement HBIM_Restoration and HBIM_Deterioration PSet.  
- Validate GlobalId with IfcOpenShell scripts.  
- Refine IfcSite geographic coordinates.  
- Regenerate complete IIIF manifests on `/media/`.  
- Extend database with flags for activities and inscriptions.  
- Provide operational guidelines for selective image publishing (public/private).  

---

## 7. Usage
- **IFC:** open [`tachara_links_v3_clean.ifc`](tachara_links_v3_clean.ifc) in  
  [BonsaiBIM](https://bonsaibim.org/) or [Solibri Anywhere](https://www.solibri.com/products/anywhere).  
  The file can also be opened with online viewers such as https://viewer.flinker.app/ or  https://viewer.sortdesk.com/ 

- **Collections demo:**  
  [HTML example](https://domenicoandreucci.github.io/hbim-tachara/collections/28bUwV09TEPxTsAjz_1GHW.html)

- **Mirador demo:**  
  [manifest example](https://domenicoandreucci.github.io/hbim-tachara/mirador.html?manifest=manifests/3AYKLOZbWgPaJV8vUibT7e.json)  
  *Note:* Mirador also supports the `iiif-content` parameter (IIIF Cookbook),  
  but this repository and scripts use `?manifest=` for consistency.

- **Integrated search:**  
  [search.html](https://domenicoandreucci.github.io/hbim-tachara/search.html?v=20)

- **Database:**  
  open [`hbim_tachara.db`](hbim_tachara.db) with [DB Browser for SQLite](https://sqlitebrowser.org/),  
  and query views `v_search` and `v_docs_year`.

- **BCF demo:**  
  open `Diacronic_View_P10.bcf` with [Flinker Viewer](https://viewer.flinker.app/) or [BIMcollab Zoom](https://www.bimcollab.com/en/zoom).

---

## 8. References## 8. References
- IIIF Consortium. *Presentation API 3.0*. 2020. <https://iiif.io/api/presentation/3.0/>  
- IIIF Consortium. *IIIF Cookbook – Content State and Mirador parameters*. <https://iiif.io/api/cookbook/>  
- buildingSMART International. *IFC 4.3.2.0 Documentation*. 2023. <https://technical.buildingsmart.org/standards/ifc/ifc-schema-specifications/>  
- buildingSMART International. *IFC Validation Service*. <https://validation.buildingsmart.org/>  
- ISO/TC46. *CIDOC-CRM v7.1.x (ISO 21127:2023)*. <http://www.cidoc-crm.org>  
- Getty Research Institute. *Art & Architecture Thesaurus Linked Open Data*. <https://www.getty.edu/research/tools/vocabularies/aat/>  
- OSArch/BlenderBIM community. *IfcDocumentReference support*. <https://community.osarch.org/>  
- Solibri. *Solibri Anywhere*. <https://www.solibri.com/products/anywhere>  
- IIIF Community. *Discussions on CORS/auth issues for hosted images*. <https://iiif.io/api/auth/1.0/>  
- Diara, F. & Rinaudo, F. *IFC Classification for FOSS HBIM: Open Issues and a Schema Proposal for Cultural Heritage Assets*. Applied Sciences, 2020. <https://www.mdpi.com/2076-3417/10/23/8320>  
- Yang, S., Hou, M. *Knowledge graph representation method for semantic 3D modeling of Chinese grottoes*. Heritage Science, 2023. <https://www.nature.com/articles/s40494-023-01084-2>  
- Historic England. *BIM for Heritage*. 2017. <https://historicengland.org.uk/images-books/publications/bim-for-heritage/>  
---

## 9. Sources for the Model

- Schmidt, E.F. with contributions by Matson, F.R., 1953. *Persepolis I: Structures, Reliefs, Inscriptions.* Oriental Institute Publications 68. Chicago: University of Chicago Press.  
- Zander, G. (ed.), 1968. *Travaux de Restauration de Monuments Historiques en Iran.* Rome: Istituto Italiano per il Medio ed Estremo Oriente (IsMEO).  
- Tilia, A.B., 1972. *Studies and Restorations at Persepolis and Other Sites of Fārs.* Rome: Istituto Italiano per il Medio ed Estremo Oriente (IsMEO).  
