# HBIM Tachara — Proofs of Concept (PoC)

This repository contains the Tachara (Persepolis) HBIM materials.

## How to use

### Search (images & GUIDs)
Open the search page (with cache-buster): https://domenicoandreucci.github.io/hbim-tachara/search.html?v=2

You can search by:
- **Free text** (label, name, photographer, owner, year, photo_id, description if present)
- **Photographer** (e.g. `Andreucci`)
- **Year** (single year; matches within `[year_start, year_end]`)
- **Photo ID** (directly returns all linked GUIDs)
- **Activities** (Restoration, Excavation, Spoliation attempt/success, Reuse, Relocation)

Results show:
- IFC GUID
- Label/Name
- Number of linked photos
- Links to **Collections** (PoC B)
- Links to **IIIF manifests** (PoC C)

You can also **Export CSV** of the current filtered results.

### Collections (PoC B)
A static HTML page per GUID, listing all photos linked to that element:
/collections/

###  IFC with HBIM PSet (PoC A)
`tachara_ready.ifc` with `HBIM_*` property sets and clickable `DocumentReference`.
Open with Solibri (Anywhere/Office).

### IIIF Manifests (PoC C)
IIIF Presentation 3.0 manifests per GUID (for Mirador):
/manifests/

**Note:** images must be publicly accessible (no auth/cookies) for Mirador to render them. Google Drive links often fail due to CORS/auth; prefer static hosting (e.g., GitHub Pages `/media/`) or a proper IIIF Image API.

## Public vs private images (Google Drive)
- Keep the main folder **private**.
- Make public only the photos you want to share:
  - Google Drive → Share → “Anyone with the link – Viewer”.
- Collections/IIIF will open only the public images; private ones will remain inaccessible.

## PoC status
- **PoC A** ✅ — IFC enriched with HBIM PSet + DocumentReference.
- **PoC B** ✅ — Collections HTML generated and published.
- **PoC C** 🔶 — Manifests are generated; to work in Mirador, publish images on a static host or enable an IIIF Image API (or ensure Drive links work without auth/CORS).

