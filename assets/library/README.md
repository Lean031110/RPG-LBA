# RPG LBA Asset Library

## Taxonomy

    assets/
      branding/                 # official identity; never replace
      characters/
        player/<class_id>/
        npc/<faction_or_region>/
      creatures/
        enemies/<species_id>/
        bosses/<boss_id>/
      equipment/
        weapons/<weapon_family>/
        armor/<slot_or_set>/
        accessories/
      environment/
        regions/<region_id>/
        city/valdeluz/
        dungeons/<dungeon_id>/
        terrain/ vegetation/ rocks/ water/ sky/
      props/
        architecture/ furniture/ containers/ tools/ lights/
      materials/
        surfaces/ decals/ atlases/
      vfx/
      ui/
      library/                  # catalog only; avoid binary duplicates

## IDs and filenames
- Immutable logical ID: lba.<type>.<slug>.v1.
- Filename: <asset_id>__<variant>.<ext>; normalize dots to underscores if required by tools.
- Variants: lod0, lod1, low, medium, high, albedo, normal, orm, roughness, metallic.
- Never use ambiguous names such as final2, new_model, test_final_final.
- One asset folder per model when it has multiple textures, rig or animations.

## Catalog vs manifest
- library/catalog.csv: production inventory, state, category, path, hash and relation to character/region/scene.
- assets/manifest.csv: author, exact source, license, URL, version, attribution and redistribution conditions.
- Every third-party asset needs a catalog ID and manifest entry before approval.
- Original LBA resources are also catalogued.
- Do not copy entire packs into the repository if redistribution terms do not allow it.

## Statuses
MISSING, PLANNED, DISCOVERED, LICENSE_REVIEW, GENERATING, PROCESSING, QA, REVIEW, APPROVED, INTEGRATED, NEEDS_IMPROVEMENT, REJECTED, QUARANTINED.
APPROVED requires real file, hash, verified license, technical QA and human visual review. INTEGRATED requires merged PR/commit.

## Content canon
- Classes: Machetero de la Sierra, Bruja de la Manigua, Sepulturero de Guanabacoa, Tirador del Malecón, Cimarrón Sombrío, Bardo del Solar.
- Enemies documented in gameplay: Sombra de Portal, Perro de ceniza, Guarapo negro.
- Regions, Valdeluz, three dungeons and five bosses follow GDD/roadmap. A PLANNED/MISSING slot does not mean the model exists.
- Visual direction: docs/08_DIRECCION_ARTISTICA_ASSETS.md and current narrative/design docs.

## Godot integration
- Preserve IDs and paths; search scene references before replacement.
- GLB/glTF preferred; validate in Godot 4.7.2 Compatibility.
- Never replace a scene-connected asset without regression testing.
- Do not store temporary renders or huge source models in runtime.
- Keep assets/manifest.csv synchronized.
