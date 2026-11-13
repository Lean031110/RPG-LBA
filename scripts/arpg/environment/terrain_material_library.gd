class_name TerrainMaterialLibrary
extends RefCounted
## Paleta regional reutilizable. Los materiales se crean una vez por zona y se comparten
## entre instancias para evitar duplicación innecesaria de recursos y draw-state changes.


static func create_valdeluz_palette() -> Dictionary:
        return {
                "grass": _noise(Color(0.22, 0.37, 0.18), 0.075, 5, 0.94, 0.0),
                "red_dirt": _noise(Color(0.51, 0.25, 0.15), 0.12, 5, 0.97, 0.0),
                "wheel_tracks": _noise(Color(0.29, 0.15, 0.105), 0.18, 4, 0.98, 0.0),
                "limestone": _noise(Color(0.62, 0.59, 0.51), 0.16, 4, 0.88, 0.0),
                "mud": _noise(Color(0.20, 0.15, 0.12), 0.21, 4, 0.96, 0.0),
                "moss": _noise(Color(0.12, 0.24, 0.13), 0.11, 4, 0.94, 0.0),
                "weathered_wood": _noise(Color(0.34, 0.22, 0.14), 0.24, 4, 0.91, 0.0),
                "wrought_iron": _noise(Color(0.17, 0.19, 0.20), 0.28, 4, 0.76, 0.48),
                "tree_bark": _noise(Color(0.25, 0.19, 0.13), 0.13, 4, 0.96, 0.0),
                "leaves_mid": VisualKit.flat_material(Color(0.16, 0.34, 0.15)),
                "leaves_dark": VisualKit.flat_material(Color(0.08, 0.20, 0.12)),
                # Fase 4B (Art Pass): materiales de shader originales, Compatibility Renderer
                # seguro (desplazamiento de vertices y mezclas en fragment). Ver ArpgArtKit.
                "puddle_wet": ArpgArtKit.wet_material(Color(0.20, 0.15, 0.12), 0.92),
                "wind_tuft": ArpgArtKit.wind_material(Color(0.10, 0.24, 0.13), 0.07, 1.9),
                "wind_frond": ArpgArtKit.wind_material(Color(0.16, 0.34, 0.15), 0.045, 1.4),
                "wind_canopy": ArpgArtKit.wind_material(Color(0.09, 0.22, 0.12), 0.05, 1.2),
                "worn_iron": ArpgArtKit.worn_iron_material(),
        }


static func _noise(
        base_color: Color,
        frequency: float,
        detail: int,
        surface_roughness: float,
        metalness: float
) -> StandardMaterial3D:
        var material := VisualKit.noise_material(base_color, frequency, detail)
        material.uv1_triplanar = true
        material.roughness = surface_roughness
        material.metallic = metalness
        return material
