{den, inputs, ...}:
{
  flake-file.inputs.noctalia= {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia-desktop = {
    includes = [
      den.aspects.niri
      ];

    nixos = { host, pkgs, ... }: {
      imports = [ inputs.noctalia.nixosModules.default ];

      # Enable Noctalia shell systemd service
      services.noctalia-shell = {
        enable = true;
      };

      # Additional packages that complement Noctalia
      environment.systemPackages = with pkgs; [
        brightnessctl
        playerctl
        pamixer
        libnotify
      ];
    };

    # per-user
    homeManager = { user, ... }: {
      imports = [ inputs.noctalia.homeModules.default ];
      
      
      programs.noctalia-shell = {
        enable = true;
        settings = builtins.fromJSON (builtins.readFile ./../.configs/noctalia.json);
          /*
          {
          # alternatively
          
          #(builtins.fromJSON (builtins.readFile ../.configs/noctalia.json)).settings;
          
          settingsVersion = 54;
          bar = {
            barType = "floating";
            position = "top";
            monitors = [ ];
            density = "comfortable";
            showOutline = true;
            showCapsule = true;
            capsuleOpacity = 0.91;
            capsuleColorKey = "none";
            widgetSpacing = 4;
            contentPadding = 6;
            fontScale = 1.15;
            backgroundOpacity = 0.61;
            useSeparateOpacity = true;
            floating = true;
            marginVertical = 4;
            marginHorizontal = 4;
            frameThickness = 8;
            frameRadius = 12;
            outerCorners = true;
            hideOnOverview = true;
            displayMode = "always_visible";
            autoHideDelay = 500;
            autoShowDelay = 150;
            showOnWorkspaceSwitch = true;
            widgets = {
              left = [
                {
                  id = "Launcher";
                  colorizeSystemIcon = "none";
                  customIconPath = "";
                  enableColorization = false;
                  icon = "rocket";
                  iconColor = "none";
                  useDistroLogo = false;
                }
                { id = "plugin:todo"; }
                {
                  id = "Clock";
                  clockColor = "none";
                  customFont = "";
                  formatHorizontal = "HH:mm ddd, MMM dd";
                  formatVertical = "HH mm - dd MM";
                  tooltipFormat = "HH:mm ddd, MMM dd";
                  useCustomFont = false;
                }
                {
                  id = "SystemMonitor";
                  compactMode = true;
                  diskPath = "/";
                  iconColor = "none";
                  showCpuFreq = false;
                  showCpuTemp = true;
                  showCpuUsage = true;
                  showDiskAvailable = false;
                  showDiskUsage = false;
                  showDiskUsageAsPercent = false;
                  showGpuTemp = false;
                  showLoadAverage = false;
                  showMemoryAsPercent = false;
                  showMemoryUsage = true;
                  showNetworkStats = false;
                  showSwapUsage = false;
                  textColor = "none";
                  useMonospaceFont = true;
                  usePadding = false;
                }
                { id = "plugin:privacy-indicator"; }
                {
                  id = "ActiveWindow";
                  colorizeIcons = false;
                  hideMode = "hidden";
                  maxWidth = 145;
                  scrollingMode = "hover";
                  showIcon = true;
                  textColor = "none";
                  useFixedWidth = false;
                }
                {
                  id = "MediaMini";
                  compactMode = false;
                  hideMode = "hidden";
                  hideWhenIdle = false;
                  maxWidth = 145;
                  panelShowAlbumArt = true;
                  scrollingMode = "hover";
                  showAlbumArt = true;
                  showArtistFirst = true;
                  showProgressRing = true;
                  showVisualizer = false;
                  textColor = "none";
                  useFixedWidth = false;
                  visualizerType = "linear";
                }
                { id = "plugin:pomodoro"; }
              ];
              center = [
                {
                  id = "Workspace";
                  characterCount = 2;
                  colorizeIcons = false;
                  emptyColor = "secondary";
                  enableScrollWheel = true;
                  focusedColor = "primary";
                  followFocusedScreen = false;
                  groupedBorderOpacity = 1;
                  hideUnoccupied = false;
                  iconScale = 0.8;
                  labelMode = "index";
                  occupiedColor = "secondary";
                  pillSize = 0.6;
                  showApplications = false;
                  showBadge = true;
                  showLabelsOnlyWhenOccupied = true;
                  unfocusedIconsOpacity = 1;
                }
                {
                  id = "Taskbar";
                  colorizeIcons = false;
                  hideMode = "transparent";
                  iconScale = 0.8;
                  maxTaskbarWidth = 40;
                  onlyActiveWorkspaces = true;
                  onlySameOutput = true;
                  showPinnedApps = true;
                  showTitle = false;
                  smartWidth = false;
                  titleWidth = 120;
                }
                { id = "plugin:catwalk"; }
              ];
              right = [
                { id = "plugin:niri-animation-picker"; }
                {
                  id = "AudioVisualizer";
                  colorName = "primary";
                  hideWhenIdle = true;
                  width = 200;
                }
                {
                  id = "Tray";
                  blacklist = [ ];
                  chevronColor = "none";
                  colorizeIcons = true;
                  drawerEnabled = true;
                  hidePassive = false;
                  pinned = [ ];
                }
                {
                  id = "NotificationHistory";
                  hideWhenZero = false;
                  hideWhenZeroUnread = false;
                  iconColor = "none";
                  showUnreadBadge = true;
                  unreadBadgeColor = "primary";
                }
                {
                  id = "Volume";
                  displayMode = "onhover";
                  iconColor = "none";
                  middleClickCommand = "pwvucontrol || pavucontrol";
                  textColor = "none";
                }
                {
                  id = "Brightness";
                  applyToAllMonitors = false;
                  displayMode = "onhover";
                  iconColor = "none";
                  textColor = "none";
                }
                {
                  id = "ControlCenter";
                  colorizeDistroLogo = false;
                  colorizeSystemIcon = "tertiary";
                  customIconPath = "";
                  enableColorization = true;
                  icon = "noctalia";
                  useDistroLogo = true;
                }
              ];
            };
            mouseWheelAction = "content";
            reverseScroll = false;
            mouseWheelWrap = true;
            screenOverrides = [ ];
          };
          general = {
            avatarImage = "/home/avanonyme/.face";
            dimmerOpacity = 0.2;
            showScreenCorners = true;
            forceBlackScreenCorners = false;
            scaleRatio = 1;
            radiusRatio = 1.2;
            iRadiusRatio = 1;
            boxRadiusRatio = 1;
            screenRadiusRatio = 1.29;
            animationSpeed = 1.7;
            animationDisabled = false;
            compactLockScreen = false;
            lockScreenAnimations = true;
            lockOnSuspend = true;
            showSessionButtonsOnLockScreen = true;
            showHibernateOnLockScreen = true;
            enableLockScreenMediaControls = true;
            enableShadows = true;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            language = "";
            allowPanelsOnScreenWithoutBar = true;
            showChangelogOnStartup = true;
            telemetryEnabled = false;
            enableLockScreenCountdown = true;
            lockScreenCountdownDuration = 10000;
            autoStartAuth = false;
            allowPasswordWithFprintd = false;
            clockStyle = "analog";
            clockFormat = "hh\nmm";
            passwordChars = false;
            lockScreenMonitors = [ ];
            lockScreenBlur = 0.51;
            lockScreenTint = 0.4;
            keybinds = {
              keyUp = [ "Up" ];
              keyDown = [ "Down" ];
              keyLeft = [ "Left" ];
              keyRight = [ "Right" ];
              keyEnter = [ "Return" "Enter" ];
              keyEscape = [ "Esc" ];
              keyRemove = [ "Del" ];
            };
            reverseScroll = false;
          };
          ui = {
            fontDefault = "Sans Serif";
            fontFixed = "monospace";
            fontDefaultScale = 0.9;
            fontFixedScale = 1;
            tooltipsEnabled = true;
            boxBorderEnabled = true;
            panelBackgroundOpacity = 0.93;
            panelsAttachedToBar = true;
            settingsPanelMode = "attached";
            settingsPanelSideBarCardStyle = false;
          };
          location = {
            name = "Montreal, Canada";
            weatherEnabled = true;
            weatherShowEffects = true;
            useFahrenheit = false;
            use12hourFormat = false;
            showWeekNumberInCalendar = true;
            showCalendarEvents = true;
            showCalendarWeather = true;
            analogClockInCalendar = true;
            firstDayOfWeek = -1;
            hideWeatherTimezone = false;
            hideWeatherCityName = false;
          };
          calendar = {
            cards = [
              { enabled = true; id = "calendar-header-card"; }
              { enabled = true; id = "calendar-month-card"; }
              { enabled = true; id = "weather-card"; }
            ];
          };
          wallpaper = {
            enabled = true;
            overviewEnabled = true;
            directory = "/home/avanonyme/Pictures/Wallpapers";
            monitorDirectories = [ ];
            enableMultiMonitorDirectories = false;
            showHiddenFiles = false;
            viewMode = "single";
            setWallpaperOnAllMonitors = true;
            fillMode = "crop";
            fillColor = "#000000";
            useSolidColor = false;
            solidColor = "#1a1a2e";
            wallpaperChangeMode = "random";
            transitionDuration = 1500;
            transitionType = "random";
            skipStartupTransition = false;
            transitionEdgeSmoothness = 0.05;
            panelPosition = "center";
            hideWallpaperFilenames = false;
            overviewBlur = 0.4;
            overviewTint = 0.6;
            useWallhaven = true;
            wallhavenQuery = "nature forest solarpunk";  # or "abstract", whatever fits your aesthetic
            wallhavenSorting = "relevance";
            wallhavenPurity = "100";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "1920";
            automationEnabled = true;
            randomIntervalSec = 600;
            wallhavenOrder = "desc";
            wallhavenCategories = "111";
            wallhavenRatios = "";
            wallhavenApiKey = "";
            wallhavenResolutionHeight = "";
            sortOrder = "name";
            favorites = [ ];
          };
          appLauncher = {
            enableClipboardHistory = true;
            autoPasteClipboard = false;
            enableClipPreview = true;
            clipboardWrapText = true;
            clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
            clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
            position = "center";
            pinnedApps = [ ];
            useApp2Unit = false;
            sortByMostUsed = true;
            terminalCommand = "ghostty";
            customLaunchPrefixEnabled = false;
            customLaunchPrefix = "";
            viewMode = "grid";
            showCategories = true;
            iconMode = "native";
            showIconBackground = false;
            enableSettingsSearch = true;
            enableWindowsSearch = true;
            enableSessionSearch = true;
            ignoreMouseInput = false;
            screenshotAnnotationTool = "";
            overviewLayer = false;
            density = "comfortable";
          };
          controlCenter = {
            position = "close_to_bar_button";
            openAtMouseOnBarRightClick = true;
            diskPath = "/dev";
            shortcuts = {
              left = [
                { id = "Network"; }
                { id = "Bluetooth"; }
                { id = "WallpaperSelector"; }
                { id = "NoctaliaPerformance"; }
              ];
              right = [
                { id = "Notifications"; }
                { id = "PowerProfile"; }
                { id = "KeepAwake"; }
                { id = "NightLight"; }
              ];
            };
            cards = [
              { enabled = true;  id = "profile-card"; }
              { enabled = true;  id = "shortcuts-card"; }
              { enabled = true;  id = "audio-card"; }
              { enabled = false; id = "brightness-card"; }
              { enabled = true;  id = "weather-card"; }
              { enabled = true;  id = "media-sysmon-card"; }
            ];
          };
          systemMonitor = {
            cpuWarningThreshold = 80;
            cpuCriticalThreshold = 90;
            tempWarningThreshold = 80;
            tempCriticalThreshold = 90;
            gpuWarningThreshold = 80;
            gpuCriticalThreshold = 90;
            memWarningThreshold = 80;
            memCriticalThreshold = 90;
            swapWarningThreshold = 80;
            swapCriticalThreshold = 90;
            diskWarningThreshold = 80;
            diskCriticalThreshold = 90;
            diskAvailWarningThreshold = 20;
            diskAvailCriticalThreshold = 10;
            batteryWarningThreshold = 20;
            batteryCriticalThreshold = 5;
            enableDgpuMonitoring = true;
            useCustomColors = false;
            warningColor = "";
            criticalColor = "";
            externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
          };
          dock = {
            enabled = true;
            position = "bottom";
            displayMode = "auto_hide";
            dockType = "floating";
            backgroundOpacity = 1;
            floatingRatio = 1;
            size = 0.79;
            onlySameOutput = true;
            monitors = [ ];
            pinnedApps = [ ];
            colorizeIcons = false;
            showLauncherIcon = true;
            launcherPosition = "end";
            launcherIconColor = "primary";
            pinnedStatic = true;
            inactiveIndicators = true;
            groupApps = true;
            groupContextMenuMode = "extended";
            groupClickAction = "cycle";
            groupIndicatorStyle = "dots";
            deadOpacity = 0.4;
            animationSpeed = 1;
            sitOnFrame = false;
            showDockIndicator = true;
            indicatorThickness = 6;
            indicatorColor = "secondary";
            indicatorOpacity = 0.78;
          };
          network = {
            wifiEnabled = true;
            airplaneModeEnabled = false;
            bluetoothRssiPollingEnabled = false;
            bluetoothRssiPollIntervalMs = 60000;
            networkPanelView = "wifi";
            wifiDetailsViewMode = "grid";
            bluetoothDetailsViewMode = "grid";
            bluetoothHideUnnamedDevices = false;
            disableDiscoverability = false;
          };
          sessionMenu = {
            enableCountdown = true;
            countdownDuration = 10000;
            position = "center";
            showHeader = true;
            showKeybinds = true;
            largeButtonsStyle = true;
            largeButtonsLayout = "grid";
            powerOptions = [
              { action = "lock";         command = ""; countdownEnabled = true; enabled = true; keybind = "1"; }
              { action = "suspend";      command = ""; countdownEnabled = true; enabled = true; keybind = "2"; }
              { action = "hibernate";    command = ""; countdownEnabled = true; enabled = true; keybind = "3"; }
              { action = "reboot";       command = ""; countdownEnabled = true; enabled = true; keybind = "4"; }
              { action = "logout";       command = ""; countdownEnabled = true; enabled = true; keybind = "5"; }
              { action = "shutdown";     command = ""; countdownEnabled = true; enabled = true; keybind = "6"; }
              { action = "rebootToUefi"; command = ""; countdownEnabled = true; enabled = true; keybind = "7"; }
            ];
          };
          notifications = {
            enabled = true;
            enableMarkdown = true;
            density = "default";
            monitors = [ ];
            location = "top_right";
            overlayLayer = true;
            backgroundOpacity = 1;
            respectExpireTimeout = false;
            lowUrgencyDuration = 3;
            normalUrgencyDuration = 8;
            criticalUrgencyDuration = 15;
            clearDismissed = true;
            saveToHistory = {
              low = true;
              normal = true;
              critical = true;
            };
            sounds = {
              enabled = false;
              volume = 0.5;
              separateSounds = false;
              criticalSoundFile = "";
              normalSoundFile = "";
              lowSoundFile = "";
              excludedApps = "discord,firefox,chrome,chromium,edge";
            };
            enableMediaToast = true;
            enableKeyboardLayoutToast = true;
            enableBatteryToast = true;
          };
          osd = {
            enabled = true;
            location = "top_right";
            autoHideMs = 2000;
            overlayLayer = true;
            backgroundOpacity = 1;
            enabledTypes = [ 0 1 2 3 ];
            monitors = [ ];
          };
          audio = {
            volumeStep = 5;
            volumeOverdrive = true;
            cavaFrameRate = 30;
            visualizerType = "wave";
            mprisBlacklist = [ ];
            preferredPlayer = "";
            volumeFeedback = true;
            volumeFeedbackSoundFile = "";
          };
          brightness = {
            brightnessStep = 5;
            enforceMinimum = true;
            enableDdcSupport = false;
            backlightDeviceMappings = [ ];
          };
          colorSchemes = {
            useWallpaperColors = true;
            predefinedScheme = "Noctalia (default)";
            darkMode = true;
            schedulingMode = "on";
            manualSunrise = "06:30";
            manualSunset = "18:30";
            generationMethod = "tonal-spot";
            monitorForColors = "";
          };
          templates = {
            activeTemplates = [
              { enabled = true; id = "zenBrowser"; }
              { enabled = true; id = "ghostty"; }
              { enabled = true; id = "steam"; }
              { enabled = true; id = "niri"; }
              { enabled = true; id = "gtk"; }
              { enabled = true; id = "code"; }
              { enabled = true; id = "qt"; }
              { enabled = true; id = "sway"; }
            ];
            enableUserTheming = false;
          };
          nightLight = {
            enabled = true;
            forced = false;
            autoSchedule = true;
            nightTemp = "4622";
            dayTemp = "6500";
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };
          hooks = {
            enabled = false;
            wallpaperChange = "";
            darkModeChange = "";
            screenLock = "";
            screenUnlock = "";
            performanceModeEnabled = "";
            performanceModeDisabled = "";
            startup = "";
            session = "";
          };
          idle = {
            enabled = false;
            screenOffTimeout = 600;
            lockTimeout = 660;
            suspendTimeout = 1800;
            fadeDuration = 5;
            screenOffCommand = "";
            lockCommand = "";
            suspendCommand = "";
            resumeScreenOffCommand = "";
            resumeLockCommand = "";
            resumeSuspendCommand = "";
            customCommands = "[]";
          };
          desktopWidgets = {
            enabled = true;
            overviewEnabled = true;
            gridSnap = false;
            monitorWidgets = [ ];
          };
          
        };*/
      };
    };
  };
}
