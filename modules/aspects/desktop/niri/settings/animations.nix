{inputs,...}:{

    den.aspects.desktop.niri-animations = {
        imports = [ inputs.niri-nix.homeModules.default ];

        homeManager = {
            wayland.windowManager.niri.settings ={

                animations = {
                    slowdown = 3.0;
                    window-open = {
                        duration-ms = 250;
                        "custom-shader" = builtins.readFile ./shaders/smoke-window-open.glsl;
                    };

                    window-close = {
                        duration-ms = 250;
                        "custom-shader" = builtins.readFile ./shaders/smoke-window-close.glsl;
                    };

                    window-resize = {
                        "custom-shader" = builtins.readFile ./shaders/prism-window-resize.glsl;
                    };

                }
            };
        };
    };
}