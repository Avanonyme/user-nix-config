{den, ...}:
{
  den.aspects.app-bundles.ai = {
    includes = with den.aspects;[
      apps.ollama
      apps.pi
      apps.hyprwhispr
      apps.aionui
    ];
  };
}