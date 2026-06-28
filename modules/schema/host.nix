{ lib, inputs, den, self, ... }: 
let
  inherit (lib) mkOption types;

  # ... other helpers: interfaceType, channel definitions, etc. ...

  settingsType =
  let
    # Keys that are NOT children of an aspect: structural keys (includes,
    # nixos, ...), plus your framework's class names and quirk/extension keys.
    # Adapt these three sources to your own framework.
    inherit (den.lib.aspects.fx.keyClassification) structuralKeysSet;
    classKeys = den.classes or { };
    quirkKeys = den.quirks or { };
    skipKey = k: structuralKeysSet ? ${k} || classKeys ? ${k} || quirkKeys ? ${k};

    # settings can be a plain options-attrset ({ foo = mkOption {...}; })
    # OR module-shaped ({ imports; config; options; }). Normalize both to one shape.
    reshapeSettings =
      raw:
      let
        # Distinct names on purpose — see the statix note under "Gotchas".
        imports' = raw.imports or [ ];
        config' = raw.config or { };
      in
      {
        imports = imports';
        config = config';
        options = removeAttrs raw [ "imports" "config" ];
      };

    # True if this place, or anything below it, declares settings.
    hasSettingsDeep =
      node:
      builtins.isAttrs node
      && (
        (node ? settings)
        || lib.any (k: !(skipKey k) && hasSettingsDeep (node.${k} or null)) (builtins.attrNames node)
      );

    # Build the submodule for one place (node) in the aspect tree, mirroring
    # the tree. Merge this place's own settings with its children's settings.
    nodeModule =
      node:
      let
        ownSettings =
          if node ? settings then
            reshapeSettings node.settings
          else
            { imports = [ ]; config = { }; options = { }; };

        settingChildren = lib.filterAttrs (
          k: v: !(skipKey k) && builtins.isAttrs v && hasSettingsDeep v
        ) node;

        childOptions = lib.mapAttrs (
          name: child:
          mkOption {
            type = types.submodule (nodeModule child);   # recursion (calling itself)
            default = { };
            description = "Settings under ${name}";
          }
        ) settingChildren;

        # Distinct names again — keeps statix from dropping the `or` default.
        ownImports = ownSettings.imports or [ ];
        ownConfig = ownSettings.config or { };
      in
      {
        imports = ownImports;
        config = ownConfig;
        options = (ownSettings.options or { }) // childOptions;
      };
  in
  types.submodule (nodeModule (den.aspects or { }));   # start from the whole aspect tree
in
{
  den.schema.host.isEntity = true;

  den.schema.host.imports = [
    (
      { config, ... }:
      {
        options = {
          channel = mkOption { /* ... */ };
          environment = mkOption { /* ... */ };
          # ... the rest of the host's options ...

          # Here is the auto-generated settings namespace:
          settings =
            mkOption {
              type = settingsType;
              default = { };
              description = "Per-aspect typed settings";
            }
            # Keep settings out of the entity's identity (see Gotchas).
            // {
              identity = false;
            };
        };

        # config = { ... };   # computed defaults for other options, if any
      }
    )
  ];
}
